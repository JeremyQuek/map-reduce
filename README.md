<div align=center>
  <h1 style="margin: 0;"> MapReduce Programming
  </h1>
</div>



<div align="center">
<img width="800" height="500" alt="image" src="https://github.com/user-attachments/assets/7aa23b1f-e318-4ca0-92d1-223eefd30e0d" />

  
</div>


A distributed data processing system inspired by Google's original MapReduce paper, built as part of CS 162. Implements a fault-tolerant coordinator that distributes map and reduce tasks across a cluster of workers via RPC (Remote Procedure Calls), processes large datasets in parallel, and automatically recovers from worker crashes — all in C.

Obviously, this isn't the cleanest C I've ever written, but I learned a ton about distributed systems, RPC protocols, task scheduling, and why fault tolerance is genuinely hard to get right. It works, it's fast, and it survived the autograder (🙏).
