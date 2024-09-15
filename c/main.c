
#include <stdio.h>
#include <string.h>

#define CONFIG_FILE_NAME ".mobula_config"


void init() {

    printf("Initializing repository...\n");

    FILE *fptr;

    if (fptr == NULL) {
        fptr = fopen(CONFIG_FILE_NAME, "w");
        fclose(fptr);
    }
    
}


int main(int argc, char* argv[]) {

    char *command = argv[1];

    if (strcmp(command, "init") == 0) {
        init();
    }

	return 0;
}
