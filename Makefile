PYTHON ?= python3

.PHONY:
all: cpptrace chickensnake rpd rocpd remote

.PHONY: install
install: all
	$(MAKE) install -C rocpd_python
	$(MAKE) install -C rpd_tracer
	$(MAKE) install -C remote

.PHONY: uninstall
uninstall:
	$(MAKE) uninstall -C rocpd_python
	$(MAKE) uninstall -C rpd_tracer
	$(MAKE) uninstall -C remote

.PHONY: clean
clean: cpptrace-clean
	$(MAKE) clean -C rocpd_python
	$(MAKE) clean -C rpd_tracer
	$(MAKE) clean -C remote

.PHONY: rpd
rpd:
	$(MAKE) -C rpd_tracer
.PHONY: rocpd
rocpd:
	$(MAKE) -C rocpd_python
.PHONY: remote
remote:
	$(MAKE) -C remote 
.PHONY: cpptrace

CPPTRACE_MAKE?= $(wildcard cpptrace/Makefile)
ifneq ($(CPPTRACE_MAKE),)
cpptrace:
	cd cpptrace; cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=../cpptrace_install; cmake --build build; cmake --install build
cpptrace-clean:
	$(MAKE) clean -C cpptrace
else
cpptrace:
cpptrace-clean:
endif

.PHONY: chickensnake
CHICKENSNAKE_MAKE?= $(wildcard chickensnake/Cargo.toml)
ifneq ($(CHICKENSNAKE_MAKE),)
chickensnake:
	cd chickensnake; cargo build -r; cp chickensnake.h ../rpd_tracer/.; cp target/release/libchickensnake.so ../rpd_tracer/.; sed -i 's/PythonSpy/void*/' ../rpd_tracer/chickensnake.h
chickensnake-clean:
	cd chickensnake; cargo clean
else
chickensnake:
chickensnake-clean:
endif
