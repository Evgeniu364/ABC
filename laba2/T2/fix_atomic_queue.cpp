#include <stdio.h>
#include <iostream>
#include <queue>
#include <thread>
#include <numeric>

using namespace std;

class FixedQueue {
private:
    atomic<uint8_t>* buffer;
    int size;
    atomic<int> FRONT;
    atomic<int> REAR;

public:
    FixedQueue(int size) {
        this->size = size;
        FRONT = 0;
        REAR = 0;
        buffer = new atomic<uint8_t>[size];
        for (int i = 0; i < size; i ++)
            buffer[i] = 0;
    }

    void push(uint8_t val){
        while (true) {
            int rear = FRONT.load();
            if (rear == REAR.load() + size) {
                continue;
            }

            uint8_t tmp = buffer[rear % size];
            if (tmp != 0){
                continue;
            }

            if (FRONT.compare_exchange_strong(rear, rear + 1)){
                if (buffer[rear % size].compare_exchange_strong(tmp, val)){
                    return;
                }

            }
        }
    }

    bool pop(uint8_t& val){
        auto rear = REAR.load();
        if (rear  == FRONT.load()) {
            return false;
        }

        uint8_t tmp = buffer[rear % size];
        if (tmp == 0){
            return false;
        }
        if (REAR.compare_exchange_strong(rear, rear + 1)) {
            if (buffer[rear % size].compare_exchange_strong(tmp, 0)) {
                val = tmp;
                return true;
            }
        }
        return false;
    }

    ~FixedQueue() {
        delete[] buffer;
    }
};



int main(){

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

    return 0;
}