/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   mandatory.c                                        :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: mkugan <mkugan@student.42berlin.de>        +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/05/26 16:14:08 by mkugan            #+#    #+#             */
/*   Updated: 2025/05/27 00:07:37 by mkugan           ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../get_next_line.h"

int	main(int argc, char **argv)
{
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

	if (argc == 2 && strcmp(argv[1], "closed_fd") == 0)
    {
		int fd = open("a.out", O_RDONLY);
		if (fd != -1)
			close(fd);
        char *line = get_next_line(fd);
        if (line)
        {
            printf("%s", line);
            free(line);
        }
        return 0;
    }


    if (argc != 2)
    {
        fprintf(stderr, "Usage: %s filename\n", argv[0]);
        return 1;
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
