#include <iostream>
#include <vector>
#include <thread>

using namespace std;

void atomic_counter(int numTasks, int numThreads, bool sleep) {

    vector<uint8_t> vctr(numTasks, 0);
    vector<thread> threads;
    atomic<int> global = 0;

    threads.reserve(numThreads);
    auto start = chrono::high_resolution_clock::now();
    for (int i = 0; i < numThreads; i++) {
        threads.emplace_back([&] {
            int local = global.fetch_add(1);
            while (local < numTasks) {
                vctr.at(local) = 1;
                local = global.fetch_add(1);
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
    auto stop = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<chrono::milliseconds>(stop - start);

    cout << "Время, затраченное на функцию с " << numThreads << " потоками" << ": "
              << duration.count() << " мс" << endl;


    for(auto i : vctr){
        if (i != 1){
            cout << "Не все единицы" << std::endl;
            break;
        }
    }


}

int main() {
    int F = 1024 * 1024;

    atomic_counter(F, 4, false);
    atomic_counter(F, 8, false);
    atomic_counter(F, 16, false);
    atomic_counter(F, 32, false);
    atomic_counter(F, 4, true);
    atomic_counter(F, 8, true);
    atomic_counter(F, 16, true);
    atomic_counter(F, 32, true);

    return 0;
}
