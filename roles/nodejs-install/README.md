# NOTE: ########################################################################
copied from <https://github.com/nodesource/ansible-nodejs-role/tree/cbbbfe10fa71ca3f5cc7a98e549c2a4e06fc2f3b>
to update, download again and replace this folder <https://github.com/nodesource/ansible-nodejs-role/archive/master.zip>

--------------------------------------------------------------------------------

# ansible-nodejs-role

This is an Ansible role which adds the the NodeSource APT repository and installs Node.js.

Currently this role supports the following operating systems and releases.

* **Ubuntu 14.04 LTS** (Trusty Tahr)
* **Ubuntu 16.04 LTS** (Xenial Xerus)

## Usage

You can either:

* Install the playbook via Ansible Galaxy:

```text
$ ansible-galaxy install nodesource.node
```

* Install the using [requirements.yml via Ansible Galaxy](http://docs.ansible.com/ansible/galaxy.html#installing-multiple-roles-from-a-file):

```yml
- src: https://github.com/nodesource/ansible-nodejs-role
```

```text
$ ansible-galaxy install -r requirements.txt
```

## Configure

Then configure it as follows:

```yaml
- hosts: servers
  roles:
     - nodesource.node
```

## Role Variables

- `nodejs_nodesource_pin_priority`: Pin-Priority of the NodeSource repository (default: `500`).
- `nodejs_version`: Set Node version (options: `12` or `14`)

## Testing

To test this role using [molecule](https://github.com/metacloud/molecule):

```
$ make
$ molecule test
```

## Author

Mark Wolfe <mark@wolfe.id.au>

## License

This code is Copyright (c) 2014 NodeSource and Mark Wolfe and licenced under the MIT licence. All rights not explicitly granted in the MIT license are reserved. See the included [LICENSE.md](./LICENSE.md) file for more details.
