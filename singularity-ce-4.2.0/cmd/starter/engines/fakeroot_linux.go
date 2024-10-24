// Copyright (c) 2019-2022, Sylabs Inc. All rights reserved.
// This software is licensed under a 3-clause BSD license. Please consult the
// LICENSE.md file distributed with the sources of this project regarding your
// rights to use or distribute this software.

//go:build fakeroot_engine

package engines

import (
	// register the fakeroot runtime engine
	_ "github.com/sylabs/singularity/v4/internal/pkg/runtime/engine/fakeroot"
)
