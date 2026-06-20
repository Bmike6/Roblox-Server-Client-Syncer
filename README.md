# Roblox-Server-Client-Syncer
This is a roblox module that I built to simulate logic being passed on the server. It supports realtime live update support up to months at a single time. 



To answer questions:

What is the point of using this module? This module acts as a gate to bridge the path so you can simulate synced data with the client and server, without offloading every thread to a certain object runtime.

Is this easy to use? Very easy create your sync object add the required information to run your states, and whenever you are ready to begin your state machine sync call it on the server and it will automatically keep
track of all changes happening to that object on a period of time passed recommend update sync time is 1 second and call the sync update function whenever the server needs to verify integreity

Feaatures?
  supports multiple states
  supports completion state callbacks
  supports extremely close safe sync
  supports print debugging


Please credit me if you use this module happy coding

