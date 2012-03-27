## zkclustertest

_"There's a reason they call it a *cluster*" - Nathan Olla_

This code is an adaptation of similar (and possibly better) code out there that does the legwork to set up a zookeeper cluster. In the Grand Tradition of Not Invented Here, I rewrote it using the tools I know best (ruby, rake) so that I could modify it as needed. 

The script is essentially a rakefile that generates the config files to point to the other members of the cluster, set up data directories, and start the cluster. Rather than write a whole bunch of code to manage process lifetime and children and such, we'll just use tmux. 



