#!/usr/bin/make -f

# Target directory inside the package staging area
DEB_DESTDIR = $(CURDIR)/debian/gluten-velox-spark/usr/share/gluten

%:
	dh $@

override_dh_auto_clean:
	# Avoid cleaning if Maven or native assets aren't initialized yet
	[ ! -d build ] || ./build/mvn clean || true

override_dh_auto_configure:
	# No separate configuration phase required for Maven layouts

override_dh_auto_build:
	# Compile using the identical Scala 2.13 and Java 21 bypass parameters
	./build/mvn clean install \
		-DskipTests \
		-Pscala-2.13 \
		-Dscala.version=2.13.13 \
		-Dscala.binary.version=2.13 \
		-Pbackends-velox \
		-Dscalastyle.skip=true \
		-Dspotless.check.skip=true

override_dh_auto_install:
	# Create target deployment paths inside the staging directory
	mkdir -p $(DEB_DESTDIR)
	
	# Copy the finalized 96MB Velox bundle artifact into the package structure
	cp package/target/gluten-velox-bundle-spark3.5_2.13-linux_amd64-1.6.0.jar $(DEB_DESTDIR)/

override_dh_shlibdeps:
	# Skip native shared library dependency generation if embedded statically inside the JAR
	# Prevents lintian errors regarding C++ symbol references inside the binary bundle
	dh_shlibdeps --dpkg-shlibdeps-params=--ignore-missing-info || true

