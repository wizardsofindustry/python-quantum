#######################################################################
#
# QUANTUM MAKEFILE
#
#	This Makefile exposes various targets related to the compiling
#	and building of the `quantum` application.
#
#######################################################################


clean:
	rm -rf var
	rm -rf .coverage.*
	rm -rf .coverage

env:
	virtualenv env
