#include <iostream>
#include <vector>
#include <thread>
#include <mutex>

using namespace std;
void mutex_counter(int numTasks, int numThreads, bool sleep) {
    mutex mtx;
    int global = 0;
    vector<thread> threads;
    vector<uint8_t> vctr(numTasks, 0);

    threads.reserve(numThreads);

    auto start = chrono::high_resolution_clock::now();

    for (int i = 0; i < numThreads; i++) {
        threads.emplace_back([&] {
            while (true) {
                mtx.lock();
                int local = global;
                if (local == numTasks) {
                    mtx.unlock();
                    return;
                }

                vctr.at(local) = 1;
                global++;
                mtx.unlock();

                if (sleep) {
                    this_thread::sleep_for(chrono::nanoseconds(10));
                }
            }
        });
    }
    for (auto &thread: threads) {
        if (thread.joinable()) {
            thread.join();
        }
    }

    auto stop = chrono::high_resolution_clock::now();
    auto duration = chrono::duration_cast<chrono::milliseconds>(stop - start);
    cout << "Время, затраченное на функцию с  " << numThreads << " потоками " << ": "
         << duration.count() << " мс " << endl;

    for(auto i : vctr){
        if (i != 1){
            cout << "Не все единицы" << std::endl;
            break;
        }
    }
}

int main() {


    int F = 1024 * 1024;

    mutex_counter(F, 4, false);
    mutex_counter(F, 8, false);
    mutex_counter(F, 16, false);
    mutex_counter(F, 32, false);
    mutex_counter(F, 4, true);
    mutex_counter(F, 8, true);
    mutex_counter(F, 16, true);
    mutex_counter(F, 32, true);

    return 0;
}