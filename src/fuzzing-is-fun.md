## The grapheme splitting problem

I've [written before](https://ha.nnes.dev/blog/why-ascii-is-worse) about how complex Unicode can be.
For example, to split a string into its graphemes (the smallest visual units of a string), requires handling thousands of edge cases.
Even though the `🫱🏾‍🫲🏻` emoji (Handshake: Medium-Dark Skin Tone, Light Skin Tone) appears as one grapheme, it's made of five codepoints (`🫱` the rightwards hand, ` 🏾` a medium-dark skin tone modifier, an invisible zero width joiner, `🫲` a leftwards hand and ` 🏻` a light skin tone modifier).
The Unicode specification goes into [excruciating (but necessary) detail](https://www.unicode.org/reports/tr29/#Grapheme_Cluster_Boundaries) about how this grapheme splitting algorithm should work.

Roc's [Unicode package](https://github.com/roc-lang/unicode) implements functions for UTF-8 strings, including the `Grapheme.split` function.
The current implementation manages to pass all the [official Unicode tests](https://www.unicode.org/reports/tr44/#Algorithm_Test_Table), but there's still a branch in the code where the function is hardcoded to crash.
One of the authors, [Luke Boswell](https://lukewilliamboswell.github.io/) reached out to me to try and find a test case that would trigger this code branch so that it could be implemented properly.

## Finding the crash

One way to find bugs in situations like this is fuzzing, which means sending semi-random input to your program until it crashes.
Fuzzers can use existing input examples to generate new inputs, or analyse your code to craft inputs that are more likely to cause crashes.

I used the [radamsa](https://gitlab.com/akihe/radamsa) fuzzer, which takes some example inputs and mutates using predefined rules.
Simple mutations might be things like mutating characters, adding whitespace or repeating data.
A more involved mutation could take the example input `beans123` and change the number to try and crash a number parser by changing it to the maximum value of an unsigned 64-bit integer, so the output string would be `beans18446744073709551616`.

I used the existing Unicode test suite as input examples for the fuzzer, these test cases include tricky edge cases like ` ਃ가` (a Gurmukhi combining diacritic followed by a Hangul syllable).
I wrote a short Roc app that just runs `Grapheme.split` on its input and set up a loop that pipes the fuzzer output to the Roc app and dumps any errors to a text file.
After an hour of running I managed to get 30 test cases that crashed the Roc app.
Some of the test cases were short like `ใ␁ᅠ‍ऀ` (A Thai character,an invisible start of heading character, a Hangul filler character, an invisible zero width joiner and a Devanagari diacritic).
Other test cases were megabytes long, clearly radamsa has a mutation that tries to send way more input than the program is expecting. 😅
Looking over all the new test cases, they were all situations where unexpected things were being joined with a zero width joiner character.
I opened [an issue](https://github.com/roc-lang/unicode/issues/19) on the `roc-unicode` repo explaining my findings.

## What next?

Roc doesn't have an integrated fuzzer yet, so I had to use a generic fuzzer that could communicate through stdin/stdout or through files, but other languages do have more integrated fuzzers.
The more advanced fuzzers can analyse which code paths are being taken, and craft specific inputs to explore your code more thoroughly.
For more information about fuzzing, check out [this episode](https://pod.link/1602572955/episode/65188ba1e1074b3ed68292a208c5710b) of the Software Unscripted podcast with [Brendan Hansknecht](https://github.com/bhansconnect), it's fascinating how advanced this technique can get.
