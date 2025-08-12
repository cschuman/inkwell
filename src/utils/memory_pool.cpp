#include "utils/memory_pool.h"
#include <algorithm>
#include <cstring>

namespace mdviewer {

// MemoryPool implementation
MemoryPool::MemoryPool(size_t block_size, size_t initial_blocks)
    : block_size_(block_size) {
    blocks_.reserve(initial_blocks);
    for (size_t i = 0; i < initial_blocks; ++i) {
        blocks_.emplace_back(block_size_);
    }
}

MemoryPool::~MemoryPool() = default;

void* MemoryPool::allocate(size_t bytes, size_t alignment) {
    return do_allocate(bytes, alignment);
}

void MemoryPool::deallocate(void* ptr, size_t bytes, size_t alignment) {
    do_deallocate(ptr, bytes, alignment);
}

void* MemoryPool::do_allocate(size_t bytes, size_t alignment) {
    // Try to allocate from current block
    if (current_block_ < blocks_.size()) {
        void* result = allocate_from_block(blocks_[current_block_], bytes, alignment);
        if (result) {
            allocated_bytes_.fetch_add(bytes, std::memory_order_relaxed);
            size_t current = allocated_bytes_.load(std::memory_order_relaxed);
            size_t peak = peak_bytes_.load(std::memory_order_relaxed);
            while (current > peak && !peak_bytes_.compare_exchange_weak(peak, current)) {}
            return result;
        }
    }
    
    // Try next blocks
    for (size_t i = current_block_ + 1; i < blocks_.size(); ++i) {
        void* result = allocate_from_block(blocks_[i], bytes, alignment);
        if (result) {
            current_block_ = i;
            allocated_bytes_.fetch_add(bytes, std::memory_order_relaxed);
            size_t current = allocated_bytes_.load(std::memory_order_relaxed);
            size_t peak = peak_bytes_.load(std::memory_order_relaxed);
            while (current > peak && !peak_bytes_.compare_exchange_weak(peak, current)) {}
            return result;
        }
    }
    
    // Need to grow
    grow();
    return allocate(bytes, alignment);
}

void MemoryPool::do_deallocate(void* ptr, size_t bytes, size_t alignment) {
    // Simple memory pool doesn't deallocate individual allocations
    // Memory is reclaimed when the pool is reset or destroyed
    allocated_bytes_.fetch_sub(bytes, std::memory_order_relaxed);
}

bool MemoryPool::do_is_equal(const std::pmr::memory_resource& other) const noexcept {
    return this == &other;
}

void* MemoryPool::allocate_from_block(Block& block, size_t bytes, size_t alignment) {
    // Align the current position
    size_t aligned_pos = (block.used + alignment - 1) & ~(alignment - 1);
    
    if (aligned_pos + bytes <= block.size) {
        void* result = block.memory.get() + aligned_pos;
        block.used = aligned_pos + bytes;
        return result;
    }
    
    return nullptr;
}

void MemoryPool::grow() {
    // Double the block size for the new block
    size_t new_block_size = block_size_ * (blocks_.size() + 1);
    blocks_.emplace_back(new_block_size);
    current_block_ = blocks_.size() - 1;
}

void MemoryPool::reset() {
    for (auto& block : blocks_) {
        block.used = 0;
    }
    current_block_ = 0;
    allocated_bytes_.store(0, std::memory_order_relaxed);
}

// ArenaAllocator implementation
ArenaAllocator::ArenaAllocator(size_t size)
    : memory_(std::make_unique<char[]>(size)), size_(size), offset_(0) {}

ArenaAllocator::~ArenaAllocator() = default;

void* ArenaAllocator::allocate(size_t bytes, size_t alignment) {
    size_t aligned_offset = align_up(offset_, alignment);
    
    if (aligned_offset + bytes > size_) {
        throw std::bad_alloc();
    }
    
    void* result = memory_.get() + aligned_offset;
    offset_ = aligned_offset + bytes;
    
    return result;
}

void ArenaAllocator::reset() {
    offset_ = 0;
}

// ObjectPool implementation
template<typename T>
ObjectPool<T>::ObjectPool(size_t initial_capacity) {
    pool_.reserve(initial_capacity);
    available_.reserve(initial_capacity);
    
    for (size_t i = 0; i < initial_capacity; ++i) {
        auto obj = std::make_unique<T>();
        available_.push_back(obj.get());
        pool_.push_back(std::move(obj));
    }
    
    available_count_.store(initial_capacity, std::memory_order_relaxed);
}

template<typename T>
ObjectPool<T>::~ObjectPool() = default;

template<typename T>
template<typename... Args>
T* ObjectPool<T>::acquire(Args&&... args) {
    std::lock_guard<std::mutex> lock(mutex_);
    
    if (available_.empty()) {
        // Grow the pool
        auto obj = std::make_unique<T>(std::forward<Args>(args)...);
        T* ptr = obj.get();
        pool_.push_back(std::move(obj));
        return ptr;
    }
    
    T* obj = available_.back();
    available_.pop_back();
    available_count_.fetch_sub(1, std::memory_order_relaxed);
    
    // Reinitialize the object
    new(obj) T(std::forward<Args>(args)...);
    
    return obj;
}

template<typename T>
void ObjectPool<T>::release(T* obj) {
    if (!obj) return;
    
    std::lock_guard<std::mutex> lock(mutex_);
    
    // Call destructor but don't deallocate
    obj->~T();
    
    available_.push_back(obj);
    available_count_.fetch_add(1, std::memory_order_relaxed);
}

// Explicit template instantiations for common types
template class ObjectPool<std::string>;
template class ObjectPool<std::vector<uint8_t>>;

} // namespace mdviewer