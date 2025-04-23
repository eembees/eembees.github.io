drafts:
	hugo serve --disableFastRender --buildDrafts

serve: 
	hugo serve --disableFastRender


install:
	git submodule update --init --recursive
