
install:
	rm -rf /usr/local/bin/ws-rsync
	rm -rf /var/lib/ws-rsync
	mkdir -p /var/lib/ws-rsync/
	cp temp.yml /var/lib/ws-rsync/
	cp ws-rsync /usr/local/bin/

uninstall:
	rm -rf /var/lib/ws-rsync /usr/local/bin/ws-rsync


