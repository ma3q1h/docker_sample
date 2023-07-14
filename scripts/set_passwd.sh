#make jupyter setting file
cd ${HOME}
jupyter notebook --generate-config

#save default setting as ".old"
cp ${HOME}/.jupyter/jupyter_notebook_config.py ${HOME}/.jupyter/jupyter_notebook_config.py.old
#copy setting for open access
cp ${HOME}/scripts/jupyter_notebook_config.py ${HOME}/.jupyter/jupyter_notebook_config.py

#set password
echo 'SET PASSWORD FOR JUPYTER NOTEBOOK'
PASSWD=$(python3.9 -c 'from notebook.auth import passwd;print(passwd())' | tee /dev/tty)
if [ "`echo $PASSWD | grep 'Passwords do not match'`" ]; then
  echo "RETRY"
else
  echo c.NotebookApp.password=\'${PASSWD}\' >> ${HOME}/.jupyter/jupyter_notebook_config.py
  echo "DONE"
fi
