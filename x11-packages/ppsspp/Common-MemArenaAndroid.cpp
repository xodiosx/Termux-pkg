#include "ppsspp_config.h"

#ifdef __ANDROID__

#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <cerrno>
#include <alloca.h>
#include <cstring>

#include "Common/Log.h"
#include "Common/MemoryUtil.h"
#include "Common/MemArena.h"
#include "Common/StringUtils.h"
#include "Common/System/System.h"

bool MemArena::NeedsProbing() {
	return false;
}

static int termux_shm_unlink(const char *name) {
	size_t namelen;
	char *fname;

	while (name[0] == '/') ++name;

	if (name[0] == '\0') {
		errno = EINVAL;
		return -1;
	}

	namelen = strlen(name);
	fname = (char *) alloca(sizeof("@TERMUX_PREFIX@/tmp/") - 1 + namelen + 1);
	memcpy(fname, "@TERMUX_PREFIX@/tmp/", sizeof("@TERMUX_PREFIX@/tmp/") - 1);
	memcpy(fname + sizeof("@TERMUX_PREFIX@/tmp/") - 1, name, namelen + 1);

	return unlink(fname);
}

static int termux_shm_open(const char *name, int oflag, mode_t mode) {
	size_t namelen;
	char *fname;
	int fd;

	while (name[0] == '/') ++name;

	if (name[0] == '\0') {
		errno = EINVAL;
		return -1;
	}

	namelen = strlen(name);
	fname = (char *) alloca(sizeof("@TERMUX_PREFIX@/tmp/") - 1 + namelen + 1);
	memcpy(fname, "@TERMUX_PREFIX@/tmp/", sizeof("@TERMUX_PREFIX@/tmp/") - 1);
	memcpy(fname + sizeof("@TERMUX_PREFIX@/tmp/") - 1, name, namelen + 1);

	fd = open(fname, oflag, mode);
	if (fd != -1) {
		int flags = fcntl(fd, F_GETFD, 0);
		flags |= FD_CLOEXEC;
		flags = fcntl(fd, F_SETFD, flags);

		if (flags == -1) {
			int save_errno = errno;
			close(fd);
			fd = -1;
			errno = save_errno;
		}
	}

	return fd;
}

size_t MemArena::roundup(size_t x) {
	return x;
}

bool MemArena::GrabMemSpace(size_t size) {
	const char *name = "PPSSPP_RAM";

	fd = termux_shm_open(name, O_RDWR | O_CREAT, 0600);
	if (fd < 0) {
		ERROR_LOG(Log::MemMap, "Failed to grab shared memory space of size: %08x  errno: %d", (int)size, (int)(errno));
		return false;
	}

	if (ftruncate(fd, size) < 0) {
		ERROR_LOG(Log::MemMap, "Failed to truncate shared memory to size: %08x  errno: %d", (int)size, (int)(errno));
		close(fd);
		fd = -1;
		return false;
	}

	return true;
}

void MemArena::ReleaseSpace() {
	if (fd >= 0) {
		termux_shm_unlink("PPSSPP_RAM");
		close(fd);
	}
	fd = -1;
}

void *MemArena::CreateView(s64 offset, size_t size, void *base) {
	void *retval = mmap(base, size, PROT_READ | PROT_WRITE, MAP_SHARED | ((base == 0) ? 0 : MAP_FIXED), fd, offset);
	if (retval == MAP_FAILED) {
		NOTICE_LOG(Log::MemMap, "mmap on shared memory (fd: %d) failed", (int)fd);
		return nullptr;
	}
	return retval;
}

void MemArena::ReleaseView(s64 offset, void *view, size_t size) {
	munmap(view, size);
}

u8 *MemArena::Find4GBBase() {
#if PPSSPP_ARCH(64BIT)
	const uint64_t EIGHT_GIGS = 0x200000000ULL;
	void *base = mmap(0, EIGHT_GIGS, PROT_READ | PROT_WRITE, MAP_ANON | MAP_SHARED, -1, 0);
	if (base && base != MAP_FAILED) {
		INFO_LOG(Log::System, "base: %p", base);
		uint64_t aligned_base = ((uint64_t)base + 0xFFFFFFFF) & ~0xFFFFFFFFULL;
		INFO_LOG(Log::System, "aligned_base: %p", (void *)aligned_base);
		munmap(base, EIGHT_GIGS);
		return reinterpret_cast<u8 *>(aligned_base);
	} else {
		u8 *hardcoded_ptr = reinterpret_cast<u8 *>(0x2300000000ULL);
		INFO_LOG(Log::System, "Failed to anonymously map 8GB. Fall back to the hardcoded pointer %p.", hardcoded_ptr);
		return hardcoded_ptr;
	}
#else
	void *base = mmap(0, 0x10000000, PROT_READ | PROT_WRITE, MAP_ANON | MAP_SHARED, -1, 0);

	if (base == MAP_FAILED) {
		ERROR_LOG(Log::System, "Failed to map 256 MB of memory space: %s", strerror(errno));
		return nullptr;
	}

	munmap(base, 0x10000000);
	return static_cast<u8 *>(base);
#endif
}

#endif  // __ANDROID__
