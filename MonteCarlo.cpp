#include <iostream>
#include <cstdlib>
#include <cmath>
#include <ctime>
#include <cstdio>

using namespace std;

int count(int TRIES)
{
	int hits = 0;
	srand(time(0));  // Seed the timer
	for (int i = 1; i <= TRIES; i++)
	{
		double r = rand() * 1.0 / RAND_MAX; //  Between 0 and 1
		double x = -1 + 2 * r; //  Between -1 and 1
		r=rand() * 1.0 / RAND_MAX;
		double y = -1 + 2 * r;
		if (x * x + y * y <= 1)
		{
			hits++;
		}
	}
	return (hits);
}

int main()
{	
	cout << "Please enter the number of darts to approximate pi: "<<endl;
	int TRIES;
	cin >> TRIES;
	clock_t time_a = clock();
	int circle = count(TRIES);
	double pi_estimate = 4.0 * circle/TRIES;
	cout << "Estimate for pi: " << pi_estimate << endl;
	clock_t time_b = clock();
	double total_time_ticks = (double)(time_b-time_a) / CLOCKS_PER_SEC;
	cout << "Total time: " << total_time_ticks << endl;
	return 0;
}
