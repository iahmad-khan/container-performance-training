dockerinstallubuntu:
	sudo apt-get update
	sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu `lsb_release -cs` stable"
	sudo apt-get update
	sudo apt-get install -y docker-ce

dockerinstallfedora:
	sudo dnf -y install dnf-plugins-core
	sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
	sudo dnf -y install docker-ce

dockerstart:
	sudo systemctl start docker

bccinstall:
	@# Assumes Ubuntu 17.10 (Artful), Xenial also supported
	echo "deb [trusted=yes] https://repo.iovisor.org/apt/artful artful-nightly main" | sudo tee /etc/apt/sources.list.d/iovisor.list
	sudo apt-get update
	sudo apt-get install -y bcc-tools libbcc-examples linux-headers-`uname -r`

bccinstallfedora:
	@# Assumes FC27, 25/26 also supported
	echo -e '[iovisor]\nbaseurl=https://repo.iovisor.org/yum/nightly/f27/$$basearch\nenabled=1\ngpgcheck=0' \
		| sudo tee /etc/yum.repos.d/iovisor.repo
	sudo dnf -y install bcc-tools kernel-devel-`uname -r` kernel-headers-`uname -r`

otherinstallubuntu:
	sudo apt-get install -y sysstat linux-tools-`uname -r` git

otherinstallfedora:
	sudo dnf -y install perf git sysstat

fetchlabs:
	git clone --depth=1 https://github.com/goldshtn/linux-tracing-workshop labs

buildjavadocker:
	sudo docker build -t java - < Dockerfile.java

demouse:
	sudo docker run --rm -d --name app -v /run -v $(CURDIR)/labs/buggy:/src java sh -c 'javac /src/Computey.java -d /run && yes | java -cp /run -XX:+PreserveFramePointer -Xcomp Computey 2 10000000 4'

demoperf1:
	sudo docker run --rm -d --name app -v /run -v $(CURDIR)/labs:/src gcc:6 sh -c 'g++ -g -fno-inline -fno-omit-frame-pointer -O2 /src/matexp.cc -o /run/matexp && /run/matexp /src/a.mat 10000000 /run/b.mat'

demoperf1record:
	sudo perf record -e cpu-clock -F 97 -a -G docker/`sudo docker inspect app --format="{{.Id}}"` -g -- sleep 10

demoperf1record2:
	sudo perf record -F 97 -p `pidof matexp` -g -- sleep 10

demoperf2:
	sudo docker run --rm -d --name app -v /run -v $(CURDIR)/labs/buggy:/src java sh -c 'javac /src/Allocy.java -d /run && java -cp /run -XX:+PreserveFramePointer -Xcomp Allocy'

demoperf2record:
	sudo perf record -F 97 -p `pidof java` -g -- sleep 10
	sudo docker exec app sh -c 'cd /agent/out && java -cp attach-main.jar:$$JAVA_HOME/lib/tools.jar net.virtualvoid.perf.AttachOnce `pidof java`'

demologger:
	sudo docker run --rm -d --name app -v /run -v $(CURDIR)/labs:/src gcc:6 sh -c 'gcc -g -lpthread -fno-inline -fno-omit-frame-pointer /src/logger.c -o /run/logger && /run/logger'

demoblocky:
	sudo docker run --rm -d --name app -v /run -v $(CURDIR)/labs:/src gcc:6 sh -c 'gcc -g -lpthread -fno-inline -fno-omit-frame-pointer /src/blocky.c -o /run/blocky && /run/blocky'

demothrottle:
	sudo docker run --rm -d --name stress --cpus 0.5 progrium/stress -c 4

demoredis:
	sudo docker run --rm -d --name redis redis
	sudo docker run --rm --name client -it --link redis:redis redis redis-cli -h redis -p 6379
