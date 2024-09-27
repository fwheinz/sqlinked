# SQLinked - A Hybrid Approach for Local and Database-Remote Program Execution

Florian Heinz <florian.heinz@oth-regensburg.de>  
Johannes Schildgen <johannes.schildgen@oth-regensburg.de>

License: CC0

This project is an approach to execute programs partly locally and partly remote on a database server as a stored procedure. It consists of a compiler:

- sqlinked.l - Lexer definition file
- sqlinked.y - Parser definition file and compiler

and a virtual machine vm3

- Directory vm/

## Building SQLinked

### Prerequisites:
- GCC build environment
- pkg-config
- GNU flex
- GNU bison
- libpq development files (PostgreSQL client library)
- PostgreSQL server development files (13, 14 or 15)
- Graphviz

Tested with Ubuntu 22.04 LTS, the following commands build the project:

```
apt -y install build-essential pkg-config graphviz flex bison libpq-dev postgresql-server-dev-all
git clone https://github.com/fwheinz/sqlinked
cd sqlinked
make
```

# Prepare Testing

To perform the tests and reproduce the results in the corresponding research paper, a PostgreSQL database has to be installed. After that, import the file dump.sql:

    psql -U postgres < dump.sql

This creates a user and database `sqlinked` with two tables `accounts` and `logs`.

Now, edit the first line of the files `prog1`, `prog2`, `prog3` to reflect the correct database connection parameters. If you used the dump above, the username and password should already be correct, only the hostname has to be changed.

# Testing

In the three program files, *dblock* code blocks `${ ... }` are already present. For normal execution, these blocks can simply be removed or the interpreter `sqlinked` can be invoked with the `-i` parameter. The `-v` parameter gives additional infos on the program execution like stored procedure generation and timings.
Example for normal execution of prog1 with timings:
    
    ./sqlinked -vi prog1
   
   For first-time execution or after changing the program code, the stored procedures have to be created initially.
   
    ./sqlinked -vc prog1

After that, execution can be performed without (re-)creating the stored procedures

     ./sqlinked prog1
 
 
