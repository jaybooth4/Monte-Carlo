// GPU monte Carlo Simulation to calculate the value of pi

#include <unistd.h>
#include <stdio.h>
#include <curand.h>
#include <curand_kernel.h>
#define N 100
#define NUMTHREADS 32
#define NUMBLOCKS 32
#define NUMDARTS (N * NUMTHREADS * NUMBLOCKS)

__global__ void getHits (int *c) {    
    __shared__ int cache[NUMTHREADS];    
    int tid = threadIdx.x + blockIdx.x * blockDim.x;    
    int cacheIndex = threadIdx.x;
    
  // CUDA's random number library uses curandState_t to keep track of the seed value
  //   we will store a random state for every thread  
  curandState_t state;

  // we have to initialize the state 
  curand_init(tid, // the seed controls the sequence of random values that are produced 
              0, // the sequence number is only important with multiple cores 
              0, // the offset is how much extra we advance in the sequence for each call, can be 0 
              &state);

  int hits = 0;    
  double r, x, y;

    while (tid < NUMDARTS) {        
        // curand works like rand - except that it takes a state as a parameter 
        r = curand(&state) * 1.0 / (RAND_MAX); //  Between 0 and 1      
	x = -1 + 2 * r; //  Between -1 and 1
	r = curand(&state) * 1.0 / (RAND_MAX);
	y = -1 + 2 * r;
	if (((x * x) + (y * y)) <= 1)
	{
		hits++;
	}
        tid += blockDim.x * gridDim.x;    
    }        

    // set the cache values    
    cache[cacheIndex] = hits;

    __syncthreads();      

    // Reduction to sum up the results
    int i = blockDim.x/2;    
    while (i != 0) {        
        if (cacheIndex < i) {
            cache[cacheIndex] += cache[cacheIndex + i];    
        }    
        __syncthreads();        
        i /= 2;    
    }
    
    if (threadIdx.x == 0) {
	c[blockIdx.x] = cache[0]; 
    }
}

int main () {    
    int c[NUMBLOCKS]; //a[N], b[N],     
    int *dev_c;//[NUMBLOCKS]; //*dev_a, *dev_b, 
 
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    
    // allocate the memory on the GPU    
    cudaMalloc( (void**)&dev_c, NUMBLOCKS * sizeof(int) );
    
    cudaEventRecord(start);
    // copy the arrays 'a' and 'b' to the GPU    
    getHits<<<NUMBLOCKS, NUMTHREADS>>>( dev_c );    
    cudaEventRecord(stop);

    // copy the array 'c' back from the GPU to the CPU    
    cudaMemcpy( c, dev_c, NUMBLOCKS * sizeof(int), cudaMemcpyDeviceToHost );           
    double total_hits = 0.0;

    cudaEventSynchronize(stop);
    float milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, start, stop);

    printf("Milliseconds, %f\n", milliseconds);

    int i = 0;
    while(i < NUMBLOCKS) {
	    total_hits += c[i];
	    i++;
    }

    printf("total_hits %f\n", total_hits);

    double pi_estimate = 16.0 * total_hits/NUMDARTS;
    printf("Estimate for pi:  %f \n", pi_estimate);
    
// free the memory allocated on the GPU    
    cudaFree( dev_c );

    return 0; 
}
