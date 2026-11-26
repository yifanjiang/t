# tOOl

## `evaluate_submission_process.sh`

### Usage

```sh
evaluate_submission_process.sh $project $package
evaluate_submission_process.sh $package

```

`$project` can be a short name such as `SLE-15`, `SLE-15-SP1` ... `SLE-15-SP7`, `SLE-16.0`, `SLE-16.1`, or `SLE-16.2`, or a full OBS project name such as `SUSE:SLE-15-SP4:Update`.

* **Two arguments (`$project $package`):** Evaluates the submission path for `$package` in `$project`.
* **One argument (`$package`):** Shows the resolved target and devel project for `$package` across every supported release, along with whether the two projects are in sync.

The target project is resolved from OBS metadata, so inherited packages show the maintenance project they resolve to. For example, `gdm` in `SLE-15-SP5` resolves to `SUSE:SLE-15-SP4:Update`. Releases without a devel project, such as `SLE-12-SP5`, produce no line.

Both modes use the same devel-project selection logic. If the package exists in an active `Devel:Desktop` project, that project takes precedence over the corresponding `GNOME:STABLE` project. For example, `flatpak` in `SLE-15-SP5` resolves to `Devel:Desktop:SLE-15-SP5`.

---

### Examples

#### Single-argument mode (all releases)

Show the target and devel project for a package by release. Each line follows:

```text
<release>: <resolved target project> -> <devel project> sync:<Yes|No|Error>

```

*(The `sync:` values below are illustrative.)*

```sh
$ evaluate_submission_process.sh gdm
SLE-16.2: SUSE:SLFO:Main -> GNOME:Factory sync:Yes
SLE-16.1: SUSE:SLFO:1.3 -> GNOME:STABLE:48 sync:Yes
SLE-16.0: SUSE:SLFO:1.2 -> GNOME:STABLE:48 sync:No
SLE-15-SP7: SUSE:SLE-15-SP7:Update -> GNOME:STABLE:45 sync:Yes
SLE-15-SP6: SUSE:SLE-15-SP6:Update -> GNOME:STABLE:45 sync:Yes
SLE-15-SP5: SUSE:SLE-15-SP4:Update -> GNOME:STABLE:41 sync:Yes
SLE-15-SP4: SUSE:SLE-15-SP4:Update -> GNOME:STABLE:41 sync:Yes
SLE-15-SP3: SUSE:SLE-15-SP2:Update -> GNOME:STABLE:3.34 sync:Yes
SLE-15-SP2: SUSE:SLE-15-SP2:Update -> GNOME:STABLE:3.34 sync:Yes
SLE-15-SP1: SUSE:SLE-15:Update -> GNOME:STABLE:3.26 sync:Yes
SLE-15: SUSE:SLE-15:Update -> GNOME:STABLE:3.26 sync:Yes

```

* `sync:Yes`: `osc rdiff` reports no difference between the devel project and the target project.
* `sync:No`: A difference exists and should be reviewed before working on the package.
* `sync:Error`: The comparison itself failed (for example, a missing package, an authentication problem, or a network error); the reason is printed as a warning on `stderr`.

In two-argument mode, a failed comparison is reported as an error and the script exits with a non-zero status instead of offering to review the differences.

#### Two-argument mode (submission order)

With two arguments, the script evaluates the submission path and shows the devel project followed by the target project.

The command below shows the submission order for `SUSE:SLE-15-SP3:Update/gdm`:

1. Submit first to `GNOME:STABLE:3.34` as the development project.
2. Submit then to `SUSE:SLE-15-SP2:Update`. Implicitly, `SP3/gdm` inherits from `SP2:Update/gdm`, so submitting to `SP2:Update` is sufficient for both.

```sh
$ evaluate_submission_process.sh SLE-15-SP3 gdm
GNOME:STABLE:3.34

 -> SUSE:SLE-15-SP2:Update

```

Likewise, the command below shows the submission order for `SUSE:SLE-15-SP1:Update/flatpak`:

1. Submit first to `Devel:Desktop:SLE-15-SP1` as the development project (forked from `SLE-15`).
2. Submit then to `SUSE:SLE-15-SP1:Update`.

```sh
$ evaluate_submission_process.sh SLE-15-SP1 flatpak
Devel:Desktop:SLE-15-SP1
 
 -> SUSE:SLE-15-SP1:Update

```

#### Handling differences between devel and maintenance projects

When there is a **difference between the devel and maintenance project**, reviewing the difference and synchronizing as needed before starting work is strongly recommended. Otherwise, you will likely have to rebase your changes anyway.

Differences can arise for several reasons:

* A previous submission has not yet been accepted by maintenance, leaving the devel project ahead of the maintenance project.
* A previous submission bypassed the development project and went directly into maintenance, leaving the maintenance project ahead of the devel project.
* Larger incremental divergence has accumulated between the devel and maintenance projects.

Because these cases require context, a **manual review** is typically needed to decide how to proceed. **Synchronizing the package or clarifying the difference before starting work** is strongly recommended.

```sh
$ evaluate_submission_process.sh SLE-15-SP4 gdm
GNOME:STABLE:41

 -> SUSE:SLE-15-SP4:Update

Warning: Differences detected for package gdm between GNOME:STABLE:41 and SUSE:SLE-15-SP4:Update.

Do you want to review the differences? (y/N): y

```
