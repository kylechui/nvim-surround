# Changelog

## [2.0.0](https://github.com/kylechui/nvim-surround/compare/v1.0.0...v2.0.0) (2023-03-11)


### ⚠ BREAKING CHANGES

* User defined `invalid_key_behavior` handlers will be activated for control characters that don't have defined `surrounds`.
* User defined `invalid_key_behavior` handlers will be activated for control characters that don't have defined `surrounds`.
* Disable "smart" quotes.
* Remove on-the-fly scripting for queries.
* Use a somewhat reasonable naming scheme.
* Revert some changes.

### Features

* Add `&lt;Plug&gt;` mappings; decouple mappings. ([af10059](https://github.com/kylechui/nvim-surround/commit/af10059b0f1589a485d9e1b0298172bbf60cdb47))
* Add `exclude` key to `get_selections`. ([e2c22a6](https://github.com/kylechui/nvim-surround/commit/e2c22a62fe001eb7ef3bf088f4e0c439c9f9eefd))
* Allow user to add React fragments, closes [#54](https://github.com/kylechui/nvim-surround/issues/54). ([f5d4cdb](https://github.com/kylechui/nvim-surround/commit/f5d4cdba7c8e5f34863029135e6a9d3fec78ea9e))
* Disable "smart" quotes. ([87839e1](https://github.com/kylechui/nvim-surround/commit/87839e18d3953eb8cebd23a007183fd6c48863b5))
* Ignore weird Lua pattern-matching case. ([3c4fb09](https://github.com/kylechui/nvim-surround/commit/3c4fb09879e17f293494a1deefd99bb9e1d23869))
* Implement basic query-matching. ([a634889](https://github.com/kylechui/nvim-surround/commit/a634889cb4a02b370f5c5e51c925ef1bc8b1982f))
* Link to discussions page in issue template. ([4d3ea73](https://github.com/kylechui/nvim-surround/commit/4d3ea73c33c24b5bed3ac93cf0c4580488375b56))
* Make `get_selection` optionally accept list. ([#183](https://github.com/kylechui/nvim-surround/issues/183)) ([d886e22](https://github.com/kylechui/nvim-surround/commit/d886e228a790b41e5239926817dfdc81394abd77))
* Remove on-the-fly scripting for queries. ([48540cf](https://github.com/kylechui/nvim-surround/commit/48540cf24c1744c8f089099270fa8acea2672125))
* Start the beginnings of queries. ([df1c68f](https://github.com/kylechui/nvim-surround/commit/df1c68f8fd6252a5657479aab88742f2f5f2c6b8))
* Support control characters for modifying `surrounds`. ([#179](https://github.com/kylechui/nvim-surround/issues/179)) ([#209](https://github.com/kylechui/nvim-surround/issues/209)) ([e65628a](https://github.com/kylechui/nvim-surround/commit/e65628a21131b83e89d4dec9842f47ed1e41aee7))
* Support control characters in `surrounds`. ([#179](https://github.com/kylechui/nvim-surround/issues/179)) ([#211](https://github.com/kylechui/nvim-surround/issues/211)) ([ebdd22d](https://github.com/kylechui/nvim-surround/commit/ebdd22d2040798d0b5a5e50d72d940e95f308121))
* Update the bug report template. ([193193d](https://github.com/kylechui/nvim-surround/commit/193193d377ad0ff32f539dcd087c56e6620d7fb6))
* Use a somewhat reasonable naming scheme. ([8431c4e](https://github.com/kylechui/nvim-surround/commit/8431c4ee8d74021e51261d5b62aa45525d71ed84))


### Bug Fixes

* `&lt;Plug&gt;(nvim-surround-insert) mapping`. ([#176](https://github.com/kylechui/nvim-surround/issues/176)) ([6b45fbf](https://github.com/kylechui/nvim-surround/commit/6b45fbffdabb2d8cd80d310006c92e59cec8fd74))
* Add indentation when using line mode. ([#185](https://github.com/kylechui/nvim-surround/issues/185)) ([9da7ced](https://github.com/kylechui/nvim-surround/commit/9da7ced872fd7d654f2677b1a11d1f294cfaa66d))
* Add protected call around Tree-sitter module. ([d91787d](https://github.com/kylechui/nvim-surround/commit/d91787d5a716623be7cec3be23c06c0856dc21b8))
* Change `reset_cursor` semantics. ([a207e3b](https://github.com/kylechui/nvim-surround/commit/a207e3b9906f86ecf48a90d94bb2eb703c141798))
* Change type annotations to `|nil` from `?`. ([1ac5abf](https://github.com/kylechui/nvim-surround/commit/1ac5abf6b6c9fdfbf4d793b9bf3a3b0938c6faf3))
* Correctly restore visual selection marks. ([#155](https://github.com/kylechui/nvim-surround/issues/155)) ([c6a1993](https://github.com/kylechui/nvim-surround/commit/c6a1993199237f875f9407eb1c0aa9176117a3ff))
* Failing test cases due to Tree-sitter dependency. ([c057fb8](https://github.com/kylechui/nvim-surround/commit/c057fb81f1496a88722e201eeb71bba06d532076))
* Fix catastrophic error that broke everything. ([c323fa5](https://github.com/kylechui/nvim-surround/commit/c323fa5c8e84a59ab9aa63e07bdb28cc8c124c2a))
* Fix quote bug, closes [#172](https://github.com/kylechui/nvim-surround/issues/172). ([58b0a55](https://github.com/kylechui/nvim-surround/commit/58b0a55e8922e17250376045460df178ab7cf1c1))
* Handle special characters for getchar. ([#170](https://github.com/kylechui/nvim-surround/issues/170)) ([1f79449](https://github.com/kylechui/nvim-surround/commit/1f79449d14463c6512a6f806f0023301e7a2c713))
* Improper lookbehind for quotes. ([1d83fec](https://github.com/kylechui/nvim-surround/commit/1d83fecd27c6b4b66cc529930552d205fbecb660))
* Improper table handling for `add`, resolves [#191](https://github.com/kylechui/nvim-surround/issues/191). ([d51d554](https://github.com/kylechui/nvim-surround/commit/d51d554ae4721a20c892998a76d8a2edf6f75c08))
* Minor bugs. ([7f7ca04](https://github.com/kylechui/nvim-surround/commit/7f7ca045648912c03f565e91e2b6ba91e85b9a33))
* Properly handle linewise normal surrounds. ([90821ad](https://github.com/kylechui/nvim-surround/commit/90821ad682aac189cd0a38fd83fc96f0cbcc5d29))
* Remove `remap = true` from keymaps. ([#219](https://github.com/kylechui/nvim-surround/issues/219)) ([89c82e7](https://github.com/kylechui/nvim-surround/commit/89c82e7c71a735f7c7d6330ba55a2fffb962d1e1))
* Revert some changes. ([ce01942](https://github.com/kylechui/nvim-surround/commit/ce01942a8f5d9e170493a67235568fe294cbb83d))
* Revert to pattern-based function calls by default. ([ba19320](https://github.com/kylechui/nvim-surround/commit/ba19320c14b5425c57c02c486c3eff76d7c8769f))
* spelling mistakes ([#162](https://github.com/kylechui/nvim-surround/issues/162)) ([7e5096b](https://github.com/kylechui/nvim-surround/commit/7e5096b736ae252d04d543af6a13280125dc6d0f))
* Support Lua 5.1 instead of only LuaJIT. ([#169](https://github.com/kylechui/nvim-surround/issues/169)) ([fa7648e](https://github.com/kylechui/nvim-surround/commit/fa7648e3ed5ec22f32de06d366cf8b80141998f0))
* Tweak pattern for function calls. ([3accef6](https://github.com/kylechui/nvim-surround/commit/3accef664a99839ab1a298b02e495c9bee3cd2a3))
* Update function pattern. ([c0835d2](https://github.com/kylechui/nvim-surround/commit/c0835d2a33898b1509e804b7a3ad49737b90d98a))
* Use `line_mode` parameter when possible. ([#194](https://github.com/kylechui/nvim-surround/issues/194)) ([ad56e62](https://github.com/kylechui/nvim-surround/commit/ad56e6234bf42fb7f7e4dccc7752e25abd5ec80e))
* **utils:** Ensure chars is a table in ipairs. ([#192](https://github.com/kylechui/nvim-surround/issues/192)) ([64e2106](https://github.com/kylechui/nvim-surround/commit/64e21061953102b19bbb22e824fbb96054782799))
* wrong last_pos in visual mode when vim.o.selection='exclusive' ([#158](https://github.com/kylechui/nvim-surround/issues/158)) ([81f672a](https://github.com/kylechui/nvim-surround/commit/81f672ad6525b5d8cc27bc6ff84636cc12664485))
