#include <omp.h>
#include <iostream>
#include <ctime>

using namespace std;
typedef long long ll;
ll F(int* x, unsigned long long N, int* h)
{
	unsigned long long result = 0;
	ll i = 0;
#pragma omp parallel for  private(i) schedule(static) reduction(+:result)
	for (i = 0; i < N - 1; i++)
	{
		result += (x[i] * h[i]);

	}
	return result;
}

ll F2(int* x, unsigned long long N, int* h)
{
	unsigned long long result = 0;
	ll i = 0;
	for (i = 0; i < N - 1; i++)
	{
		result = result + (x[i] * h[i]);

	}
	return result;
}

signed main()
{
	unsigned long long count = 99999999;
	int* x = new int[count];
	int* h = new int[count];
	srand(time(NULL));

	for (ll i = 0; i < count; ++i)
	{
		x[i] = 2;

	}

	for (ll i = 0; i < count; ++i)
	{
		h[i] = 3;

	}

	unsigned int start = clock();
	F(x, count, h);
	unsigned int end = clock();
	cout << "Parallel = " << end - start << endl;
	float t = end - start;

	start = clock();
	F2(x, count, h);
	end = clock();
	float t2 = end - start;
	cout << "Not parallel = " << end - start << endl;
	cout << t2 / t << endl;




	return 0;

}