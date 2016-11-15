DIVIDER=----------------------------------------------
default:
	@(echo $(DIVIDER); cd datatypes/src; $(MAKE) -k )
	@(echo $(DIVIDER); cd useful/src; $(MAKE) -k )

clean:
	@(echo $(DIVIDER); cd datatypes/src; $(MAKE) -k clean)
	@(echo $(DIVIDER); cd useful/src; $(MAKE) -k clean)

test:
	@(echo $(DIVIDER); cd datatypes/src; $(MAKE) -k test)
	@(echo $(DIVIDER); cd useful/src; $(MAKE) -k test)