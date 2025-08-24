# AlphaFold3-on-Compute-Canada
AlphaFold3 on Compute Canada
This serves to run protein interaction predictions using compute canada and alphafold3. This allows a highthrouput approach using batch jobs, so you can submit possibly hundreds of predictions at a time and not be limited by the alphafold server.         
Alphafold 3 Compute Canada user guide
Getting Model parameters
Model parameters are only accessible through google. You can go to this link and ask for their permission https://github.com/google-deepmind/alphafold3. Note if you want to download them, be sure to have enough storage on your computer. 
Getting AlphaFold3 onto Compute Canada
AF3 only works with certain GPUs so you have to use servers like Narval (the one I am using) and I think Graham. There is an decently comprehensive wiki for the installation, or you can just paste into the terminal the same thing I pasted below:
https://docs.alliancecan.ca/wiki/AlphaFold3
In the home directory:
module load StdEnv/2023 hmmer/3.4 rdkit/2024.03.5 python/3.12
wget https://raw.githubusercontent.com/google-deepmind/alphafold3/refs/tags/v3.0.1/run_alphafold.py
virtualenv --no-download ~/alphafold3_env
source ~/alphafold3_env/bin/activate
pip install --no-index --upgrade pip
pip install --no-index alphafold3==3.0.1
build_data
python run_alphafold.py --help
pip freeze > ~/alphafold3-requirements.txt
deactivate
rm -r ~/alphafold3_env
wget https://raw.githubusercontent.com/google-deepmind/alphafold3/refs/heads/main/fetch_databases.sh
mkdir -p $SCRATCH/alphafold/dbs
bash fetch_databases.sh $SCRATCH/alphafold/dbs

Then within the alphafold/ make a directory called “model_weights” and add in the file supplied by google. AF3 should be up and running now. 

Generating Json input files
This step can probably be optimized. The script I have provided is so that you generate input files based on pasted sequences. After the sequences are two numbers. First, the length of the sequence segments, and second amount the window slides over before starting the next sequence. Be also sure to change the name of the ouput directory. You can run this directly on the Compute Canada server. 
The directory structure I like to follow is alphafold/YYYY_MM_DD_job name/”input” directory and “job” directory. Once all files have been transferred to the input directory, execute the command:
ls *.json > input_list.txt

This creates a list for the inputs, important for the batch jobs. 
You can alternatively make the json input files on the server directly to avoid having to transfer them. Either way, the input list is important. 

Running AF3
Using the provided scripts, run the data script then run the interference script. You can make the jobs dependent on each other, but that is optional. I have never done this.  
jid1=$(sbatch alphafold3-data.sh)
jid2=$(sbatch --dependency=afterok:$jid1 alphafold3-inference.sh)
sq
Make sure to change the highlighted parameters in the script and to ensure that the output directory of the first job matches the input directory of the second job. 

Evaluating AF3 outputs
Pretty self explanatory. Making sure to change the directory, execute the provided script in your home directory

module load StdEnv/2020 python/3.9
python AF3_ranking.py

This will give you a combined score as described in the Gsponer paper. https://www.pnas.org/doi/10.1073/pnas.2406407121. 

The other AF3 PAE ranking file simply gives you the lowest interchain PAE score between two different chains. 
