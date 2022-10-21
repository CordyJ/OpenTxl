test:
	./txl ultimate.question
	(echo "go"; echo "") | ./txldb ultimate.question
	./txlp ultimate.question
	./txl -c ultimate.question
	./txl -l ultimate.question
	./txlc question.txl
	./question.x ultimate.question

clean:
	/bin/rm -f *.x *.ctxl *.c *.[rp]profout
