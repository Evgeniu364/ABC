#include <iostream>
#include <vector>
#include <queue>
#include <thread>
#include <numeric>

using namespace std;

class FixedQueue {
    int size;
    uint8_t *buffer;
    unsigned long head;
    unsigned long tail;
    mutex mtx;
    condition_variable cond_empty;
    condition_variable cond_full;


public:
    FixedQueue(int size) {
        this->size = size;
        buffer = new uint8_t[size];
        head = 0;
        tail = 0;

    }

    ~FixedQueue() {
        delete[] buffer;
    }

    void push(uint8_t val) {
        unique_lock<mutex> lock(mtx);

        cond_full.wait(lock, [this] {
            return tail + size > head;
        });

        buffer[head++ & (size - 1)] = val;
        cond_empty.notify_one();
    }

    bool pop(uint8_t &val) {
        unique_lock<mutex> lock(mtx);
        if (cond_empty.wait_for(lock, chrono::milliseconds(1), [this] { return tail < head; })) {
            val = buffer[tail++ & (size - 1)];

            cond_full.notify_one();
            return true;
        } else {
            return false;
        }
    }
};

int main() {
    mutex mtx;
    FixedQueue q(16);
    vector<int> consumerNums = {1, 2, 4};
    vector<int> produserNums = {1, 2, 4};
    int taskNum = 4 * 1024 * 1024;
    for (auto consumer: consumerNums) {
        for (auto producer: produserNums) {
            atomic<int> sum(0);
            cout << "Потребители: " << consumer << endl << "Производители: " << producer << endl;
            auto producerN = [&](int i) {
                auto start = chrono::high_resolution_clock::now();
                for (int i = 0; i < taskNum; i ++) {
                    q.push(1);
                }
                auto stop = chrono::high_resolution_clock::now();
                auto duration = chrono::duration_cast<std::chrono::milliseconds>(stop - start);
                mtx.lock();
                cout << "Производитель " << i + 1 << " время --  " << duration.count()
                     << " миллисекунд" << endl;
                mtx.unlock();
            };

            auto consumerN = [&](int i) {
                auto start = chrono::high_resolution_clock::now();
                for (int i = 0; i < taskNum * producer / consumer; i ++) {
                    uint8_t poppedValue = 0;
                    while(!q.pop(poppedValue));
                    sum += poppedValue;
                }
                auto stop = chrono::high_resolution_clock::now();
                auto duration = chrono::duration_cast<std::chrono::milliseconds>(stop - start);
                mtx.lock();
                cout << "Потребитель " << i + 1 << " время --  " << duration.count()
                     << " миллисекунд" << endl;
                mtx.unlock();
            };

            vector<thread> threads;

            for (int i = 0; i < producer; i++){
                threads.emplace_back(producerN, i);
            }

            for (int i = 0; i < consumer; i++){
                threads.emplace_back(consumerN, i);
            }



            for (int i = 0; i < consumer + producer; i++)
                threads[i].join();

            cout << sum << " из " << taskNum*producer << endl;
            cout << "\n";
        }
    }
}
