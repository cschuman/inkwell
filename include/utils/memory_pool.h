#pragma once

#include <memory>
#include <vector>
#include <cstddef>
#include <atomic>
#include <memory_resource>

namespace mdviewer {

class MemoryPool : public std::pmr::memory_resource {
public:
    explicit MemoryPool(size_t block_size = 4096, size_t initial_blocks = 16);
    ~MemoryPool() override;
    
    void* allocate(size_t bytes, size_t alignment = alignof(std::max_align_t));
    void deallocate(void* ptr, size_t bytes, size_t alignment = alignof(std::max_align_t));
    
    void reset();
    
    size_t allocated_bytes() const { return allocated_bytes_.load(); }
    size_t peak_bytes() const { return peak_bytes_.load(); }
    
protected:
    void* do_allocate(size_t bytes, size_t alignment) override;
    void do_deallocate(void* ptr, size_t bytes, size_t alignment) override;
    bool do_is_equal(const std::pmr::memory_resource& other) const noexcept override;
    
private:
    struct Block {
        std::unique_ptr<char[]> memory;
        size_t size;
        size_t used;
        
        Block(size_t sz) : memory(std::make_unique<char[]>(sz)), size(sz), used(0) {}
    };
    
    std::vector<Block> blocks_;
    size_t block_size_;
    size_t current_block_ = 0;
    
    std::atomic<size_t> allocated_bytes_{0};
    std::atomic<size_t> peak_bytes_{0};
    
    void* allocate_from_block(Block& block, size_t bytes, size_t alignment);
    void grow();
};

class ArenaAllocator {
public:
    explicit ArenaAllocator(size_t size = 1024 * 1024);
    ~ArenaAllocator();
    
    template<typename T, typename... Args>
    T* create(Args&&... args) {
        void* memory = allocate(sizeof(T), alignof(T));
        return new(memory) T(std::forward<Args>(args)...);
    }
    
    template<typename T>
    T* create_array(size_t count) {
        void* memory = allocate(sizeof(T) * count, alignof(T));
        return new(memory) T[count];
    }
    
    void* allocate(size_t bytes, size_t alignment = alignof(std::max_align_t));
    
    void reset();
    
private:
    std::unique_ptr<char[]> memory_;
    size_t size_;
    size_t offset_ = 0;
    
    static size_t align_up(size_t value, size_t alignment) {
        return (value + alignment - 1) & ~(alignment - 1);
    }
};

template<typename T>
class ObjectPool {
public:
    explicit ObjectPool(size_t initial_capacity = 32);
    ~ObjectPool();
    
    template<typename... Args>
    T* acquire(Args&&... args);
    
    void release(T* obj);
    
    size_t size() const { return pool_.size(); }
    size_t available() const { return available_count_.load(); }
    
private:
    std::vector<std::unique_ptr<T>> pool_;
    std::vector<T*> available_;
    std::atomic<size_t> available_count_{0};
    std::mutex mutex_;
};

} // namespace mdviewer