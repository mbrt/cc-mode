int foo()
{
    if (a)
	while
	    (b)
	    x;
    else
	c;
    if
	(a)
	if (b)
	    x;
	else
	    y;
    if (a)
	if (b) x; else y;
    else
	z;
    if (a)
	do
	    x;
	while (b);
    else
	c;
    if (a)
	do
	    {}
	while
	    (b);
    else
	c;
    for (;;)
	if (a)
	    x;
	else c;
    do
	{}
    while (b);
    for
	(;;)
	if (a) x;
    do
	x;
    while (b);
    do
	if (y)
	    p;
	else if (p)
	    y;
	else
	    b;
    while (g);
    if (x)
	do
	    if (y) p;
	while (g);
    if (x)
	do if (y) p; while (g);
    else
	y;
    if (x)
	do x: if (y) p; while (g);
    else if (p)
	y;
  x:
    while (b)
	foo: if (y)
	    while (t)
		p;
	else t;
    while (b)
	gnkt: if (y)
	    do
		if (i)
		    while (x);
	    while (y);
    while (z);
    if (p)
	while (b)
	    gnkt: if (y)
		do if (i) while (x); while (y);
	    else
		z;
    ;
    if (x)
	do
	    while (b)
		do;
		while (d);
	while (e);
    x
	y;
    x =
	a ? b ? c : d : e;
    x =
	a :: b;
    stop;
}
#define foo					\
    p						\
    x
