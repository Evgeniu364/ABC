#include <iostream>
#include <vector>
#include <queue>
#include <thread>
#include <numeric>
#include <chrono>

using namespace std;


class Queue {

    queue<uint8_t> q;
    mutex mtx;


public:
    void push(uint8_t val) {
        mtx.lock();             
        q.push(val);
        mtx.unlock();
    }

    bool pop(uint8_t& val) {
        mtx.lock();
        if (q.empty()) {
            mtx.unlock();
            this_thread::sleep_for(chrono::milliseconds(1));
            mtx.lock();
        }
        if (q.empty()) {
            mtx.unlock();
            return false;
        }
        val = q.front();
        q.pop();
        mtx.unlock();
        return true;
    }
};

int main() {
    mutex mtx;
    Queue q;
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

