/* mprotect() workaround for Termux/Android.
 *
 * If mprotect() is called with PROT_EXEC on an existing mapping, Android
 * (SELinux execmem policy, and proot) returns EACCES/EPERM.
 *
 * Cause: https://github.com/termux/proot/commit/89bfa991cb3cb7fc78099d06d0f7e7c840cb62d1
 * Issue: https://github.com/termux-pacman/glibc-packages/issues/49
 *
 * This is a rewrite of the previous workaround, which was unsafe:
 *
 * - it used strlen() on the address argument (an address is not a string),
 * so the number of bytes copied back was undefined;
 * - it called malloc()/calloc()/free() and read /proc/self/maps from inside
 * mprotect(). mprotect() is itself called from malloc() (arena trimming)
 * and from pthread_create(), so that was a re-entrant call into the
 * allocator and could corrupt the heap ("malloc(): invalid next size").
 * This is what made byte-emulating runtimes that JIT code (Wine, FEX,
 * box64, ChakraCore, ...) die randomly during startup;
 * - it re-created the range with MAP_FIXED, discarding its content, and then
 * copied back only that bogus strlen() amount of bytes.
 *
 * This version uses the caller-provided length, allocates the scratch buffer
 * with mmap() (never malloc()) and always restores the whole range.
 *
 * GLIBC_MPROTECT_NO_WORKAROUND=1 disables the fallback (for debugging).
 */

#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sysdep.h>
#include <sys/syscall.h>

static int
workaround_enabled (void)
{
  static int cached = -1;
  const char *e;

  if (cached < 0)
    {
      e = getenv ("GLIBC_MPROTECT_NO_WORKAROUND");
      cached = (e != NULL && e[0] == 0x31) ? 0 : 1;
    }
  return cached;
}

int
__mprotect (void *addr, size_t len, int prot)
{
  int res = INLINE_SYSCALL_CALL (mprotect, addr, len, prot);

  if (res != -1)
    return res;
  if ((errno != EACCES && errno != EPERM) || (prot & PROT_EXEC) == 0)
    return res;
  if (!workaround_enabled ())
    return res;

  {
    int saved_errno = errno;
    int flags = MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED;
    void *scratch, *target;

    if (prot & PROT_GROWSDOWN)
      flags |= MAP_GROWSDOWN;

    /* Scratch copy: mmap(), not malloc() -- mprotect() can be called from
       inside the allocator, so it must not use the allocator itself.  */
    scratch = mmap (NULL, len, PROT_READ | PROT_WRITE,
                    MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (scratch == MAP_FAILED)
      {
        errno = saved_errno;
        return res;
      }

    memcpy (scratch, addr, len);

    target = mmap (addr, len, PROT_READ | PROT_WRITE | PROT_EXEC,
                   flags, -1, 0);
    if (target == MAP_FAILED)
      {
        munmap (scratch, len);
        errno = saved_errno;
        return res;
      }

    memcpy (target, scratch, len);
    munmap (scratch, len);

    res = INLINE_SYSCALL_CALL (mprotect, target, len, prot);
    if (res == -1 && (errno == EACCES || errno == EPERM))
      /* The range is already RWX/executable, Android only refuses to tighten
         it.  The caller asked for executable memory and it is executable,
         so report success.  */
      res = 0;
  }

  return res;
}

libc_hidden_def(__mprotect)
weak_alias(__mprotect, mprotect)
