 		This will walk you through all the steps i took in setting my server up.

#1 Setting up my github account
	
This was my very first time in learning github as in i learnt how to link my github to my vm via ssh and why is better to use ssh rather than original password.

# Commands i use in 
i first had to config my github with
git config --global user.name "myname"
git config --global user.email "email"

I then created my dirs and my README.md file and echo "*.swp, *swo" into .gitignore prevent or avoid pushing my vim leftovers to github:    
	

#2 I Create my directories and .md files and push then to my github to begin my work.

# Commands i use 
git status  >> to check unstage files 
git add . >> to add all files once to stage level
git commit commit -m "Description" 
git push 
