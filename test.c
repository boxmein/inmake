#include <stdio.h>
// ruby inmake.rb -f test.c -p '//#'
//# gcc -o test test.c -DAWESOME=1 
int main() {
	printf("Hello world!\n");
	if (AWESOME){
		printf("awesome!\n");
	}
}

// => gcc -o test test.c -DAWESOME=1
// ---------------------------------

#include <stdio.h>
// ruby inmake.rb -f test.c -m 'moo'

//garblegarble gcc -o test test.c -DAWESOME=1 moo
int main() {
	printf("Hello world!\n");
	if (AWESOME){
		printf("awesome!\n");
	}
}

// => gcc -o test test.c -DAWESOME=1
// ----------------------------------------------

#include <stdio.h>
// ruby inmake.rb -f test.c -r 'Z' --strip-matched

//asdf gcc -oZ test test.c -DAWESOME=1
int main() {
	printf("Hello world!\n");
	if (AWESOME){
		printf("awesome!\n");
	}
}

// => gcc -o test test.c -DAWESOME=1