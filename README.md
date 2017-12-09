Skeleton
========

Skeleton to create a basis for every PHP projects.

Create your project based on this project
-----------------------------------------

1. Download an archive of this project
2. Edit the **name** and **description** in the [composer.json](composer.json) file.
3. Remove this file (README.md)

And that's it. You have your own project.  
You may want to run `git init` to start version your project

Install
-------

The installation instructions are located in the [INSTALL.md](INSTALL.md) file.  
This file may be edited for your project if you need to perform more actions but keep it mind that it should be as simple as running one `make install` command to start working on your project.

Using a software
----------------

Simply uncomment corresponding line (do not forget to uncomment the links too) in docker-compose.yml.  
Some software requires a few step


### RabbitMQ

Add your vhost, exchange, queues and bindings in the [.provision/rabbitmq/config/setup.sh](.provision/rabbitmq/config/setup.sh) file.

Suggest change on the skeleton project 
--------------------------------------

Changes are welcome.  
You may create an issue or a Pull Request and we'll come to you.
