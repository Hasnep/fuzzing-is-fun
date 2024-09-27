root_dir := justfile_directory()
src_dir := root_dir / "src"
build_dir := root_dir / "build"

build:
    rm -rf {{ build_dir }}
    mkdir {{ build_dir }}
    cp -r {{ src_dir / "*" }} {{ build_dir }}
    pandoc {{ src_dir / "fuzzing-is-fun.md" }} --from=markdown --to=html --output={{ build_dir / "blogpost.html" }}
