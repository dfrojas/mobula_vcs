
#include "hash_table.h"
#include <dirent.h>
#include <openssl/sha.h>
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

char *walk_directory(const char *dir_path, SHA256_CTX commit_hash) {
  DIR *dir;
  struct dirent *entry;
  char path[1024];

  char *file_contents = malloc(1024 * 1024); // Allocate 1MB initially
  size_t content_size = 0;

  if (!(dir = opendir(dir_path))) {
    fprintf(stderr, "Error opening directory '%s'\n", dir_path);
    return NULL;
  }

  while ((entry = readdir(dir)) != NULL) {
    if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0 ||
        strcmp(entry->d_name, "build") == 0 ||
        strcmp(entry->d_name, "CMakeLists.txt") == 0 ||
        strcmp(entry->d_name, "hash_table.h") == 0 ||
        strcmp(entry->d_name, "main.c") == 0 ||
        strcmp(entry->d_name, ".mobula_config") == 0)
      continue;

    snprintf(path, sizeof(path), "%s/%s", dir_path, entry->d_name);

    if (entry->d_type == DT_REG) {
      FILE *fptr;
      fptr = fopen(path, "r");

      char content_file;

      while ((content_file = fgetc(fptr)) != EOF) {
        file_contents[content_size++] = content_file;
      }
      fclose(fptr);
    }
  }

  closedir(dir);
  file_contents[content_size] = '\0';
  return file_contents;
}

void commit(char *directory) {
  SHA256_CTX commit_hash;
  SHA256_Init(&commit_hash);

  HashTable *commit_data = create_table(CAPACITY);
  HashTable *files_data = create_table(CAPACITY);

  char files_data_str[20];
  snprintf(files_data_str, sizeof(files_data_str), "%p", (void *)files_data);

  ht_insert(commit_data, "files", files_data_str);

  char *file_contents = walk_directory(directory, commit_hash);
  printf("%s\n", file_contents);
  free(file_contents);

  // SHA256_Update() to update the hash with data
  // SHA256_Final() to get the final hash
}

int main(int argc, char *argv[]) {

  char *command = argv[1];

  if (strcmp(command, "init") == 0) {
    init();
  }

  if (strcmp(command, "commit") == 0) {
    commit(".");
  }

  return 0;
}
