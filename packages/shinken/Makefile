include ../../Makefile.omd


SHINKEN=shinken-1.4.1
SHINKEN_FILE=$(SHINKEN).tar.gz
SHINKEN_URL=http://shinken-monitoring.org/pub/$(SHINKEN).tar.gz
#
# MongoDB
ifeq ($(shell uname -m),x86_64)
  MONGODB=mongodb-linux-x86_64-2.4.1
else ifeq ($(shell uname -m),$(filter $(shell uname -m),i386 i486 i586 i686))
  MONGODB=mongodb-linux-i686-2.4.1
else ifeq ($(shell uname -m),armv7l)
  # http://andyfelong.com/2015/02/mongodb-on-the-raspberry-pi-2/
  MONGODB=mongodb-linux-armv7l-2.6.3
else ifeq ($(shell uname -m),armv6l)
  MONGODB=mongodb-linux-armv6l-2012-09-16
endif
MONGODB_FILE=$(MONGODB).tgz
MONGODB_URL=http://fastdl.mongodb.org/linux/$(MONGODB_FILE)
#
# This is where the python modules are going to be installed to
LOCALPYTHONDIR=$(DESTDIR)$(OMD_ROOT)/lib/python

# Find the directory where python distutils are located
PYTHONPATH=
export PYTHONPATH
DISTUTILS=$(shell python -c "import sys; import os; print [os.path.join(p, 'distutils') for p in sys.path if os.path.exists(os.path.join(p, 'distutils'))][0]")
# This is where the distutils module is temporary copied to
TMP_DISTU=$(shell pwd)/temp_distutils
PYTHONPATH=$(TMP_DISTU):$(LOCALPYTHONDIR)
export PYTHONPATH

build:
	test -f ${SHINKEN_FILE} || wget $(SHINKEN_URL)
	tar xzf $(SHINKEN_FILE)
	#set -e ; for p in patches/*.patch ; do \
	#    echo "applying $$p..." ; \
	#    ( cd $(SHINKEN) ; patch -p1 -b ) < $$p ; \
	#done
	test -f $(MONGODB_FILE) || wget $(MONGODB_URL)
	tar xzf $(MONGODB_FILE)
	if [ $(DISTRO_NAME) = "CENTOS" ] && [ $(DISTRO_VERSION) = "5" ]; then \
		echo it is a centos 5; \
		echo which has python 2.4; \
		echo we need to remove the shinken webui; \
		rm -f $(SHINKEN)/shinken/modules/active_directory_ui.py; \
	fi


install:
	rm -rf $(TMP_DISTU)
	mkdir -p $(LOCALPYTHONDIR)
	$(MAKE) installshinken
	$(MAKE) installmongodb
	echo "distro is " $(DISTRO_NAME)
	rm -rf $(TMP_DISTU)
	# cleanup the tmp directory
	for tmpfile in $(DESTDIR)$(OMD_ROOT)/tmp/easy_install* ; do \
		rm -f $$tmpfile ; \
	done
	for tmpfile in $(DESTDIR)$(OMD_ROOT)/tmp/pyro-* ; do \
		rm -f $$tmpfile ; \
	done


installshinken:
	# bin/shinken-* startfiles
	mkdir -p $(DESTDIR)$(OMD_ROOT)/bin
	install -m 755 $(SHINKEN)/bin/shinken-arbiter $(DESTDIR)$(OMD_ROOT)/bin
	install -m 755 $(SHINKEN)/bin/shinken-broker $(DESTDIR)$(OMD_ROOT)/bin
	install -m 755 $(SHINKEN)/bin/shinken-scheduler $(DESTDIR)$(OMD_ROOT)/bin
	install -m 755 $(SHINKEN)/bin/shinken-poller $(DESTDIR)$(OMD_ROOT)/bin
	install -m 755 $(SHINKEN)/bin/shinken-reactionner $(DESTDIR)$(OMD_ROOT)/bin
	install -m 755 $(SHINKEN)/bin/shinken-admin $(DESTDIR)$(OMD_ROOT)/bin
	install -m 755 $(SHINKEN)/bin/shinken-receiver $(DESTDIR)$(OMD_ROOT)/bin

	# shinken py-files
	mkdir -p $(DESTDIR)$(OMD_ROOT)/lib/shinken
	cp -r $(SHINKEN)/shinken $(DESTDIR)$(OMD_ROOT)/lib/shinken

	install -m 755 $(SHINKEN)/bin/shinken-discovery $(DESTDIR)$(OMD_ROOT)/bin
	cp -r $(SHINKEN)/libexec $(DESTDIR)$(OMD_ROOT)/lib/shinken

	install -m 755 merge-shinken-config $(DESTDIR)$(OMD_ROOT)/bin
	install -m 755 merge-shinken-specific-config $(DESTDIR)$(OMD_ROOT)/bin


installmongodb:
	mkdir -p $(DESTDIR)$(OMD_ROOT)/bin
	install -m 755 $(MONGODB)/bin/mongod $(DESTDIR)$(OMD_ROOT)/bin
	install -m 755 $(MONGODB)/bin/mongo  $(DESTDIR)$(OMD_ROOT)/bin


clean:
	rm -rf $(SHINKEN)
	rm -rf $(MONGODB)
