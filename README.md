# NAEFS

echo "# NAEFS" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M develop
git remote add origin git@github.com:NOAA-EMC/NAEFS.git
git push -u origin develop

The lastest NAEFS version is copied from /gpfs/hps/nco/ops/nwprod/naefs.v6.0.9

