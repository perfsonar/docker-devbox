#
# Makefile for Docker Dev Box
#

default:
	@echo Nothing to do here


clean:
	rm -rf $(TO_CLEAN)
	find . -name "*~" | xargs rm -rf
