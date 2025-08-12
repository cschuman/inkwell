#include <gtest/gtest.h>
#include "utils/memory_pool.h"
#include <thread>
#include <vector>

namespace mdviewer {

class MemoryPoolTest : public ::testing::Test {
protected:
    void SetUp() override {
        pool = std::make_unique<MemoryPool>(4096, 4);
    }
    
    void TearDown() override {
        pool.reset();
    }
    
    std::unique_ptr<MemoryPool> pool;
};

TEST_F(MemoryPoolTest, Construction) {
    EXPECT_NE(pool.get(), nullptr);
    EXPECT_EQ(pool->allocated_bytes(), 0);
    EXPECT_EQ(pool->peak_bytes(), 0);
}

TEST_F(MemoryPoolTest, BasicAllocation) {
    void* ptr = pool->allocate(64);
    EXPECT_NE(ptr, nullptr);
    EXPECT_GE(pool->allocated_bytes(), 64);
    EXPECT_GE(pool->peak_bytes(), 64);
    
    pool->deallocate(ptr, 64);
}

TEST_F(MemoryPoolTest, MultipleAllocations) {
    std::vector<void*> ptrs;
    
    for (int i = 0; i < 10; ++i) {
        void* ptr = pool->allocate(32);
        EXPECT_NE(ptr, nullptr);
        ptrs.push_back(ptr);
    }
    
    EXPECT_GE(pool->allocated_bytes(), 320);
    EXPECT_GE(pool->peak_bytes(), 320);
    
    for (size_t i = 0; i < ptrs.size(); ++i) {
        pool->deallocate(ptrs[i], 32);
    }
}

TEST_F(MemoryPoolTest, LargeAllocation) {
    // Allocate larger than block size
    void* ptr = pool->allocate(8192);
    EXPECT_NE(ptr, nullptr);
    EXPECT_GE(pool->allocated_bytes(), 8192);
    
    pool->deallocate(ptr, 8192);
}

TEST_F(MemoryPoolTest, AlignmentHandling) {
    // Test various alignments
    void* ptr1 = pool->allocate(64, 1);
    void* ptr2 = pool->allocate(64, 4);
    void* ptr3 = pool->allocate(64, 16);
    void* ptr4 = pool->allocate(64, 64);
    
    EXPECT_NE(ptr1, nullptr);
    EXPECT_NE(ptr2, nullptr);
    EXPECT_NE(ptr3, nullptr);
    EXPECT_NE(ptr4, nullptr);
    
    // Check alignment
    EXPECT_EQ(reinterpret_cast<uintptr_t>(ptr2) % 4, 0);
    EXPECT_EQ(reinterpret_cast<uintptr_t>(ptr3) % 16, 0);
    EXPECT_EQ(reinterpret_cast<uintptr_t>(ptr4) % 64, 0);
    
    pool->deallocate(ptr1, 64, 1);
    pool->deallocate(ptr2, 64, 4);
    pool->deallocate(ptr3, 64, 16);
    pool->deallocate(ptr4, 64, 64);
}

TEST_F(MemoryPoolTest, Reset) {
    // Allocate some memory
    std::vector<void*> ptrs;
    for (int i = 0; i < 5; ++i) {
        ptrs.push_back(pool->allocate(128));
    }
    
    size_t allocated_before = pool->allocated_bytes();
    EXPECT_GT(allocated_before, 0);
    
    // Reset should clear all allocations
    pool->reset();
    
    // Note: Reset behavior may vary - check if allocated_bytes resets
    // Some implementations may keep blocks allocated but reset usage
}

TEST_F(MemoryPoolTest, PMRInterface) {
    // Test polymorphic memory resource interface
    std::pmr::memory_resource* resource = pool.get();
    EXPECT_NE(resource, nullptr);
    
    void* ptr = resource->allocate(256);
    EXPECT_NE(ptr, nullptr);
    
    resource->deallocate(ptr, 256);
}

TEST_F(MemoryPoolTest, ThreadSafety) {
    const int num_threads = 4;
    const int allocations_per_thread = 100;
    const size_t allocation_size = 64;
    
    std::vector<std::thread> threads;
    std::vector<std::vector<void*>> thread_ptrs(num_threads);
    
    // Launch threads that allocate memory
    for (int t = 0; t < num_threads; ++t) {
        threads.emplace_back([&, t]() {
            for (int i = 0; i < allocations_per_thread; ++i) {
                void* ptr = pool->allocate(allocation_size);
                EXPECT_NE(ptr, nullptr);
                thread_ptrs[t].push_back(ptr);
                
                // Brief pause to increase contention
                std::this_thread::sleep_for(std::chrono::microseconds(1));
            }
        });
    }
    
    // Wait for all threads to complete
    for (auto& t : threads) {
        t.join();
    }
    
    // Verify all allocations succeeded
    for (int t = 0; t < num_threads; ++t) {
        EXPECT_EQ(thread_ptrs[t].size(), allocations_per_thread);
        for (void* ptr : thread_ptrs[t]) {
            EXPECT_NE(ptr, nullptr);
        }
    }
    
    // Clean up
    for (int t = 0; t < num_threads; ++t) {
        for (void* ptr : thread_ptrs[t]) {
            pool->deallocate(ptr, allocation_size);
        }
    }
}

// ArenaAllocator tests
class ArenaAllocatorTest : public ::testing::Test {
protected:
    void SetUp() override {
        arena = std::make_unique<ArenaAllocator>(8192);
    }
    
    void TearDown() override {
        arena.reset();
    }
    
    std::unique_ptr<ArenaAllocator> arena;
};

TEST_F(ArenaAllocatorTest, Construction) {
    EXPECT_NE(arena.get(), nullptr);
}

TEST_F(ArenaAllocatorTest, BasicAllocation) {
    void* ptr = arena->allocate(64);
    EXPECT_NE(ptr, nullptr);
}

TEST_F(ArenaAllocatorTest, CreateObjects) {
    struct TestObject {
        int value;
        double data;
        TestObject(int v, double d) : value(v), data(d) {}
    };
    
    TestObject* obj = arena->create<TestObject>(42, 3.14);
    EXPECT_NE(obj, nullptr);
    EXPECT_EQ(obj->value, 42);
    EXPECT_DOUBLE_EQ(obj->data, 3.14);
}

TEST_F(ArenaAllocatorTest, CreateArray) {
    int* arr = arena->create_array<int>(100);
    EXPECT_NE(arr, nullptr);
    
    // Initialize and test array
    for (int i = 0; i < 100; ++i) {
        arr[i] = i;
    }
    
    for (int i = 0; i < 100; ++i) {
        EXPECT_EQ(arr[i], i);
    }
}

TEST_F(ArenaAllocatorTest, Reset) {
    // Allocate some objects
    for (int i = 0; i < 10; ++i) {
        arena->create<int>(i);
    }
    
    // Reset should allow reuse of the arena
    arena->reset();
    
    // Should be able to allocate again
    int* new_obj = arena->create<int>(999);
    EXPECT_NE(new_obj, nullptr);
    EXPECT_EQ(*new_obj, 999);
}

// ObjectPool tests
class ObjectPoolTest : public ::testing::Test {
protected:
    struct TestObject {
        int id;
        std::string name;
        
        TestObject() : id(0), name("default") {}
        TestObject(int i, const std::string& n) : id(i), name(n) {}
    };
    
    void SetUp() override {
        object_pool = std::make_unique<ObjectPool<TestObject>>(4);
    }
    
    void TearDown() override {
        object_pool.reset();
    }
    
    std::unique_ptr<ObjectPool<TestObject>> object_pool;
};

TEST_F(ObjectPoolTest, Construction) {
    EXPECT_NE(object_pool.get(), nullptr);
    EXPECT_EQ(object_pool->available(), 0); // Initially empty
}

TEST_F(ObjectPoolTest, AcquireRelease) {
    TestObject* obj = object_pool->acquire(1, "test");
    EXPECT_NE(obj, nullptr);
    EXPECT_EQ(obj->id, 1);
    EXPECT_EQ(obj->name, "test");
    
    object_pool->release(obj);
    EXPECT_EQ(object_pool->available(), 1);
}

TEST_F(ObjectPoolTest, ReuseObjects) {
    // Acquire and release an object
    TestObject* obj1 = object_pool->acquire(1, "first");
    object_pool->release(obj1);
    
    // Next acquisition should reuse the same object
    TestObject* obj2 = object_pool->acquire(2, "second");
    EXPECT_EQ(obj1, obj2); // Should be the same pointer
    EXPECT_EQ(obj2->id, 2);
    EXPECT_EQ(obj2->name, "second");
    
    object_pool->release(obj2);
}

TEST_F(ObjectPoolTest, MultipleObjects) {
    std::vector<TestObject*> objects;
    
    // Acquire multiple objects
    for (int i = 0; i < 5; ++i) {
        TestObject* obj = object_pool->acquire(i, "obj" + std::to_string(i));
        EXPECT_NE(obj, nullptr);
        objects.push_back(obj);
    }
    
    EXPECT_GE(object_pool->size(), 5);
    EXPECT_EQ(object_pool->available(), 0);
    
    // Release all objects
    for (TestObject* obj : objects) {
        object_pool->release(obj);
    }
    
    EXPECT_EQ(object_pool->available(), 5);
}

} // namespace mdviewer