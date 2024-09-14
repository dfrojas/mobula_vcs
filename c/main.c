
#include <stdio.h>
#include <string.h>


void init() {
    printf("Initializing repository...\n");
    FILE *fptr;
    fptr = fopen(".mobula_config", "w");
    fclose(fptr);
}


int main(int argc, char* argv[])
{

    char *command = argv[1];

    if (strcmp(command, "init") == 0) {
        init();
    }

	return 0;
}
