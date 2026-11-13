# tOOl

## evaluate_submission_process.sh

__Usage__

    evaluate_submission_process.sh $project $package
    evaluate_submission_process.sh $package

`$project` can be a short name such as `SLE-15`, `SLE-15-SP1` ...
`SLE-15-SP7`, `SLE-16.0`, `SLE-16.1`, or `SLE-16.2`, or a full OBS
project name such as `SUSE:SLE-15-SP4:Update`.

With two arguments, evaluate the submission path for `$package` in
`$project`. With one argument, show the resolved target and devel
project for `$package` for every supported release.

The target project is resolved from OBS metadata, so inherited packages
show the maintenance project they resolve to. For example, `gdm` in
`SLE-15-SP5` resolves to `SUSE:SLE-15-SP4:Update`. Releases without a
devel project, such as `SLE-12-SP5`, produce no line.

__Examples__

> Show the target and devel project for a package by release. Each line
> is `<release>: <resolved target project> -> <devel project>`:
>
> $ evaluate_submission_process.sh gdm
>
> SLE-16.2: SUSE:SLFO:Main -> GNOME:Factory
> SLE-16.1: SUSE:SLFO:1.3 -> GNOME:STABLE:48
> SLE-16.0: SUSE:SLFO:1.2 -> GNOME:STABLE:48
> SLE-15-SP7: SUSE:SLE-15-SP7:Update -> GNOME:STABLE:45
> SLE-15-SP6: SUSE:SLE-15-SP6:Update -> GNOME:STABLE:45
> SLE-15-SP5: SUSE:SLE-15-SP4:Update -> GNOME:STABLE:41
> SLE-15-SP4: SUSE:SLE-15-SP4:Update -> GNOME:STABLE:41
> SLE-15-SP3: SUSE:SLE-15-SP2:Update -> GNOME:STABLE:3.34
> SLE-15-SP2: SUSE:SLE-15-SP2:Update -> GNOME:STABLE:3.34
> SLE-15-SP1: SUSE:SLE-15:Update -> GNOME:STABLE:3.26
> SLE-15: SUSE:SLE-15:Update -> GNOME:STABLE:3.26

> With two arguments, the script evaluates the submission path and shows
> the devel project followed by the target project.
>
> What the following command tells the order to submit SUSE:SLE-15-SP3:Update/gdm:
> 
> Submit first to GNOME:STABLE:3.34 as the development project
> 
> Submit then to SUSE:SLE-15-SP2:Update. Implicitly it means SP3/gdm inherits from SP2:Update/gdm, so submitting to SP2:Update is sufficient to benefit both.

$ evaluate_submission_process.sh SLE-15-SP3 gdm

GNOME:STABLE:3.34 

 -> SUSE:SLE-15-SP2:Update 

> Likewise, the command below tells the order to submit SUSE:SLE-15-SP1:Update/flatpak:
> 
> Submit first to Devel:Desktop:SLE-15-SP1 as the development project (forked from SLE-15)
> 
> Submit then to SUSE:SLE-15-SP1:Update

$ evaluate_submission_process.sh SLE-15-SP1 flatpak

Devel:Desktop:SLE-15-SP1
 
 -> SUSE:SLE-15-SP1:Update

> This is an example when there is a **difference between the devel and
> maintenance project**. Usually it means, before your real work,
> reviewing the difference and do the necessary sync is highly
> recommended. Otherwise, you will probably need to rebase your work
> any way.
>
> Please notice the difference may have various meanings.
>
> For example, if a previous submission has not been accepted by
> maintenance, the package in the devel project will be ahead of that in
> the maintenance project.
>
> On the other hand, if a previous submission did not go through the
> development project while accepted by the maintenance project, the
> package in the maintenance project will be ahead of that in the devel
> project.
>
> There might be more complicated issue that a package has a big
> incremental divergence between devel project and maintenance
> project.
> 
> Thus, usually the difference will need a **manual review** to decide
> what to do. As a general recommendation, **synchronizing the package
> or clarifying the difference before a real work** are highly
> recommended.


$ evaluate_submission_process.sh SLE-15-SP4 gdm

GNOME:STABLE:41

 -> SUSE:SLE-15-SP4:Update

Warning: Differences detected for package gdm between GNOME:STABLE:41 and SUSE:SLE-15-SP4:Update.

Do you want to review the differences? (y/N): y
