.PHONY: build

build: gtest catch2 generic

gtest:
	cd meson_gtest; mkdir subprojects || true; meson wrap install gtest || true
	cd meson_gtest; meson setup build && meson compile -C build

catch2:
	cd meson_catch2; mkdir subprojects || true; meson wrap install catch2 || true
	cd meson_catch2; meson setup build && meson compile -C build

generic:
	cd meson_generic; meson setup build && meson compile -C build

clean:
	rm -fr */build */subprojects
	
