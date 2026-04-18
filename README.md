<div align=center>
  <h1 style="margin: 0;"> A MapReduce Implementation
  </h1>
</div>



<div align="center">
<img width="800" height="450" alt="image" src="https://github.com/user-attachments/assets/7aa23b1f-e318-4ca0-92d1-223eefd30e0d" />

</div>

<br/><br/>

A distributed data processing system inspired by [Google's original MapReduce paper](https://static.googleusercontent.com/media/research.google.com/en//archive/mapreduce-osdi04.pdf), built as part of CS 162. 

Uses RPCgen as a custom protocol generator between master and worker nodes.


<div align="center">

  <img width="800" height="550" alt="Gemini_Generated_Image_iy7oryiy7oryiy7o" src="https://github.com/user-attachments/assets/4289d7be-e4bb-4e4b-940b-1c785083fe7f" />
</div>

Implements a fault-tolerant coordinator that distributes map and reduce tasks across a cluster of workers via RPC (Remote Procedure Calls), processes large datasets in parallel, and automatically recovers from worker crashes — all in C.

Obviously, this isn't the cleanest C I've ever written, but I learned a ton about distributed systems, RPC protocols, task scheduling, and why fault tolerance is genuinely hard to get right. It works, it's fast, and it survived the autograder (🙏).
