/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   bonus.c                                            :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: mkugan <mkugan@student.42berlin.de>        +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/05/26 23:20:37 by mkugan            #+#    #+#             */
/*   Updated: 2025/05/27 00:34:41 by mkugan           ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../get_next_line_bonus.h"

int	main(int argc, char **argv)
{
	if (argc == 1)
		return (0);

	if (argc == 2 && strcmp(argv[1], "stdin") == 0)
	{
		char	*line;
		while ((line = get_next_line(0)) != NULL)
        {
            printf("%s", line);
            free(line);
        }
        return 0;
    }

	if (argc == 2 && strcmp(argv[1], "neg_fd") == 0)
	{
		char *line = get_next_line(-1);
		if (line)
		{
			printf("%s", line);
			free(line);
		}
		return 0;
	}

	if (argc == 2 && strcmp(argv[1], "closed_fd") == 0)
	{
		int fd = open("test_bonus1.txt", O_RDONLY);
		close(fd);
		char *line = get_next_line(fd);
		if (line)
		{
			printf("%s", line);
			free(line);
		}
		return 0;
	}

	if (argc == 2 && strcmp(argv[1], "too_big_fd") == 0)
	{
		char *line = get_next_line(10000);
		if (line)
		{
			printf("%s", line);
			free(line);
		}
		return 0;
	}

	if (argc == 4 && strcmp(argv[1], "multi_fd") == 0)
	{
		int fd1 = open(argv[2], O_RDONLY);
int fd2 = open(argv[3], O_RDONLY);
if (fd1 < 0 || fd2 < 0)
{
    perror("open");
    return 1;
}

char *line1 = NULL;
char *line2 = NULL;
int done1 = 0;
int done2 = 0;
int toggle = 0;
while (!done1 || !done2)
{
    if (toggle == 0 && !done1)
    {
        line1 = get_next_line(fd1);
        if (line1)
        {
            printf("%s", line1);
            free(line1);
        }
        else
            done1 = 1;
    }
    else if (toggle == 1 && !done2)
    {
        line2 = get_next_line(fd2);
        if (line2)
        {
            printf("%s", line2);
            free(line2);
        }
        else
            done2 = 1;
    }
    toggle = (toggle + 1) % 2;
}
close(fd1);
close(fd2);
return 0;
	}
	int fd = open(argv[1], O_RDONLY);
    if (fd < 0)
    {
        perror("open");
        return 1;
    }

    char *line;
    while ((line = get_next_line(fd)) != NULL)
    {
        printf("%s", line);
        free(line);
    }
    close(fd);
    return 0;

}
