# uplift-packer
This repository contains Packer templates and build workflows designed for SharePoint professionals.

The uplift project offers consistent Packer/Vagrant workflows and Vagrant boxes specifically designed for SharePoint professionals. It heavy lifts low-level details of the creation of domain controllers, SQL servers, SharePoint farms and Visual Studio installs by providing a codified workflow using Packer/Vagrant tooling.

## How this works
The uplift project is split into several repositories to address particular a piece of functionality:

* [uplift-powershell](https://github.com/SubPointSolutions/uplift-powershell) - reusable PowerShell modules
* [uplift-packer](https://github.com/SubPointSolutions/uplift-packer) - Packer templates for SharePoint professionals
* [uplift-vagrant](https://github.com/SubPointSolutions/uplift-vagrant) - Vagrant plugin to simplify Windows infrastructure provisioning 
* [uplift-cicd-jenkins2](https://github.com/SubPointSolutions/uplift-cicd-jenkins2) - Jenkins server and pipelines to build uplift Packer images and Vagrant boxes

The current repository houses Packer templates and automation which is used to produces Vagrant boxes across the uplift project.

## Packer builds
Local development automation uses [Invoke-Build](https://github.com/nightroman/Invoke-Build) based tasks.

To get started, get the latest `dev` branch or fork the repo on the GitHub:
```shell
# get the source code
git clone https://github.com/SubPointSolutions/uplift-packer.git
cd uplift-packer

# checkout the dev branch
git checkout dev

# make sure we are on dev branch
git status

# optionally, pull the latest
git pull
```

Local development experience consists of [Invoke-Build](https://github.com/nightroman/Invoke-Build) tasks. Two main files are `.build.ps1` and `.build-helpers.ps1`. Use the following tasks to get started and refer to `Invoke-Build` documentation for additional help.

Run `invoke-build ?` in the corresponding folder to see available tasks.

```powershell
# show available tasks
invoke-build ?
```

### Creating packer templates
All packer templates are pre-generated via `powershell` based automation. This way enables code reuse, helps to produce `packer` template adding as many provision steps as needed.

```powershell

# rebuild all packer templates
cd packer
invoke-build 

# rebuild individual packer template
cd packer/win-2016-datacenter-app
pwsh -f '.build.ps1'
powershell -File '.build.ps1'
```

### Preparing local file repository

Some of the templates rely on external binaries. Transferring of the binaries into packer VMs is done via the local HTTP server. Build automation detects if a local HTTP server is required, automatically stands up a new server on random port padding server URL into packer builds. It automatically detects local file repository produced by `invoke-uplift` PowerShell module and uses it to server binaries for all packer builds. Refer to [uplift-powershell](https://github.com/SubPointSolutions/uplift-powershell) project for more details.

Preparing local file repository with `invoke-uplift` module:

#### Installing `Invoke-Uplift`
```powershell
# subpointsolutions-staging on myget.org
# https://www.myget.org/feed/subpointsolutions-staging/package/nuget/InvokeUplift

# register 'subpointsolutions-staging' repository
Register-PSRepository -Name "subpointsolutions-staging" -SourceLocation "https://www.myget.org/F/subpointsolutions-staging/api/v2"

# install module under PowerShell 6
pwsh -c 'Install-Module -Name "InvokeUplift" -Repository "subpointsolutions-staging"'
```

#### Downloading binaries 
```powershell
# list Microsoft binaries and updates
pwsh -c invoke-uplift resource list ms-
pwsh -c invoke-uplift resource list ms-sharepoint2016-update

# download SharePoint binaries, patches and lang packs
# wildcard match is used here
pwsh -c invoke-uplift resource download ms-sharepoint2016-rtm
pwsh -c invoke-uplift resource download ms-sharepoint2016-lang-pack
pwsh -c invoke-uplift resource download ms-sharepoint2016-update-2019

# download sql16
pwsh -c invoke-uplift resource download ms-sql-server2016-rtm

# download Visual Studio 2017
pwsh -c invoke-uplift resource download ms-visualstudio-2017.ent-installer
pwsh -c invoke-uplift resource download ms-visualstudio-2017.ent-dist-office-dev

# download Windows 2016 patches
pwsh -c invoke-uplift resource download ms-win2016-ssu-
pwsh -c invoke-uplift resource download ms-win2016-lcu-2019.01
```

### Building packer templates

Building packer templates are  handled via `invoke-build` automation at the root folder of the project. While all packer templates can be built manually within a corresponding template folder, it is highly discouraged.

Build automation runs builds in a temporary `build-packer-ci-local` folder. Every build gets an isolated folder with a branch tag. All artefacts produced by the build are stored within this folder - final packer template, packer variables file, built box and others.

To build packer VMs which require external binaries, `uplift-local-repository` folder should exist on any of the drives. Build automation scans all drives trying to find `uplift-local-repository` folder, it serves HTTP server using node js `http-server` package.

```powershell
# check which tasks are out there
invoke-build ?

# build minimal ubuntu-trusty64 box to validate all installs
invoke-build 
invoke-build -packerImageName ubuntu-trusty64

# forcing packer rebuild even if box exists
invoke-build -packerImageName ubuntu-trusty64 -Task PackerRebuild

# build windows base boxes
invoke-build -packerImageName win-2016-datacenter-soe         
invoke-build -packerImageName win-2016-datacenter-soe-latest  

# build application base boxes
# -UPLF_INPUT_BOX_NAME points to the Vagrant box to be used as a starting point
# all these boxes requires a local file repository built by invoke-uplift

invoke-build -packerImageName win-2016-datacenter-app `
  -UPLF_INPUT_BOX_NAME uplift-local/win-2016-datacenter-soe-latest-master

invoke-build -packerImageName win-2016-datacenter-app-sql16 `
  -UPLF_INPUT_BOX_NAME uplift-local/win-2016-datacenter-soe-latest-master

# build SharePoint base boxes
invoke-build -packerImageName  win-2016-datacenter-sp2016rtm-sql16-vs17 `
  -UPLF_INPUT_BOX_NAME uplift-local/win-2016-datacenter-app-sql16-master

invoke-build -packerImageName  win-2016-datacenter-sp2016fp1-sql16-vs17 `
  -UPLF_INPUT_BOX_NAME  uplift-local/win-2016-datacenter-app-sql16-master

invoke-build -packerImageName  win-2016-datacenter-sp2016fp2-sql16-vs17 `
  -UPLF_INPUT_BOX_NAME  uplift-local/win-2016-datacenter-app-sql16-master

invoke-build -packerImageName  win-2016-datacenter-sp2016latest-sql16-vs17 `
  -UPLF_INPUT_BOX_NAME  uplift-local/win-2016-datacenter-app-sql16-master

```

## Feature requests, support and contributions
All contributions are welcome. If you have an idea, create [a new GitHub issue](https://github.com/SubPointSolutions/uplift-powershell/issues). Feel free to edit existing content and make a PR for this as well.