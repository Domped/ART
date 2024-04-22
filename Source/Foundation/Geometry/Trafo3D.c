/* ===========================================================================

    Copyright (c) The ART Development Team
    --------------------------------------

    For a comprehensive list of the members of the development team, and a
    description of their respective contributions, see the file
    "ART_DeveloperList.txt" that is distributed with the libraries.

    This file is part of the Advanced Rendering Toolkit (ART) libraries.

    ART is free software: you can redistribute it and/or modify it under the
    terms of the GNU General Public License as published by the Free Software
    Foundation, either version 3 of the License, or (at your option) any
    later version.

    ART is distributed in the hope that it will be useful, but WITHOUT ANY
    WARRANTY; without even the implied warranty of MERCHANTABILITY or
    FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
    for more details.

    You should have received a copy of the GNU General Public License
    along with ART.  If not, see <http://www.gnu.org/licenses/>.

=========================================================================== */

#define ART_MODULE_NAME     Trafo3D

#include "Trafo3D.h"

ART_NO_MODULE_INITIALISATION_FUNCTION_NECESSARY

ART_NO_MODULE_SHUTDOWN_FUNCTION_NECESSARY

void trafo3d_transpose_t(
        Trafo3D  * tr
        )
{
    c3_transpose_m(
        & tr->m
        );
}

void trafo3d_t_transpose_t(
        const Trafo3D  * t0,
              Trafo3D  * tr
        )
{
    c3_m_transpose_m(
        & t0->m,
        & tr->m
        );
}

void pnt3d_p_trafo3d_p(
        const Pnt3D    * p0,
        const Trafo3D  * t0,
              Pnt3D    * pr
        )
{
    c3_cm_mul_c(
        & p0->c,
        & t0->m,
        & pr->c
        );
}

void pnt3d_p_htrafo3d_p(
        const Pnt3D     * p0,
        const HTrafo3D  * h0,
              Pnt3D     * pr
        )
{
    c3_cm_mul_c(
        & p0->c,
        & h0->m,
        & pr->c
        );

    c3_c_add_c(
        & h0->c,
        & pr->c
        );
}

void vec3d_v_trafo3d_v(
        const Vec3D    * v0,
        const Trafo3D  * t0,
              Vec3D    * vr
        )
{
    c3_cm_mul_c(
        & v0->c,
        & t0->m,
        & vr->c
        );
}

void vec3d_v_htrafo3d_v(
        const Vec3D     * v0,
        const HTrafo3D  * h0,
              Vec3D     * vr
        )
{
    c3_cm_mul_c(
        & v0->c,
        & h0->m,
        & vr->c
        );
}

void vec3d_n_htrafo3d_n(
        const Vec3D     * v0,
        const HTrafo3D  * h0,
              Vec3D     * vr
        )
{
    c3_cm_trans_mul_c(
        & v0->c,
        & h0->m,
        & vr->c
        );
}

void ray3d_r_trafo3d_r(
        const Ray3D    * r0,
        const Trafo3D  * t0,
              Ray3D    * rr
        )
{
    c3_cm_mul_c(
        & r0->point.c,
        & t0->m,
        & rr->point.c
        );

    c3_cm_mul_c(
        & r0->vector.c,
        & t0->m,
        & rr->vector.c
        );
}

void ray3d_r_htrafo3d_r(
        const Ray3D     * r0,
        const HTrafo3D  * t0,
              Ray3D     * rr
        )
{
    c3_cm_mul_c(
        & r0->point.c,
        & t0->m,
        & rr->point.c
        );

    c3_cm_mul_c(
        & r0->vector.c,
        & t0->m,
        & rr->vector.c
        );

    c3_c_add_c(
        & t0->c,
        & rr->point.c
        );
}

void box3d_b_htrafo3d_b(
        const Box3D     * b0,
        const HTrafo3D  * t0,
              Box3D     * br
        )
{
    Pnt3D  bv[8];

    bv[0] = PNT3D( BOX3D_MIN_X(*b0), BOX3D_MIN_Y(*b0), BOX3D_MIN_Z(*b0) );
    bv[1] = PNT3D( BOX3D_MAX_X(*b0), BOX3D_MIN_Y(*b0), BOX3D_MIN_Z(*b0) );
    bv[2] = PNT3D( BOX3D_MIN_X(*b0), BOX3D_MAX_Y(*b0), BOX3D_MIN_Z(*b0) );
    bv[3] = PNT3D( BOX3D_MAX_X(*b0), BOX3D_MAX_Y(*b0), BOX3D_MIN_Z(*b0) );
    bv[4] = PNT3D( BOX3D_MIN_X(*b0), BOX3D_MIN_Y(*b0), BOX3D_MAX_Z(*b0) );
    bv[5] = PNT3D( BOX3D_MAX_X(*b0), BOX3D_MIN_Y(*b0), BOX3D_MAX_Z(*b0) );
    bv[6] = PNT3D( BOX3D_MIN_X(*b0), BOX3D_MAX_Y(*b0), BOX3D_MAX_Z(*b0) );
    bv[7] = PNT3D( BOX3D_MAX_X(*b0), BOX3D_MAX_Y(*b0), BOX3D_MAX_Z(*b0) );

    *br = BOX3D_EMPTY;

    for ( int i = 0; i < 8; i++ )
    {
        Pnt3D  bvt;

        pnt3d_p_htrafo3d_p(
            & bv[i],
              t0,
            & bvt
            );

        box3d_p_add_b(
            & bvt,
              br
            );
    }
}

double trafo3d_h_det(
        const HTrafo3D  * h0
        )
{
    return
        c3_m_det(
            & h0->m
            );
}

void trafo3d_hd_invert_h(
        const HTrafo3D  * h0,
        const double      d0,
              HTrafo3D  * hr
        )
{
    c3_md_invert_m(
        & h0->m,
          d0,
        & hr->m
        );

    c3_cm_mul_c(
        & h0->c,
        & hr->m,
        & hr->c
        );

    c3_negate_c(
        & hr->c
        );
}

void trafo3d_tt_mul_t(
        const Trafo3D  * t0,
        const Trafo3D  * t1,
              Trafo3D  * tr
        )
{
    c3_mm_mul_m(
        & t0->m,
        & t1->m,
        & tr->m
        );
}

void trafo3d_hh_mul_h(
        const HTrafo3D  * h0,
        const HTrafo3D  * h1,
              HTrafo3D  * hr
        )
{
    c3_cm_mul_c(
        & h0->c,
        & h1->m,
        & hr->c
        );

    c3_mm_mul_m(
        & h0->m,
        & h1->m,
        & hr->m
        );

    c3_c_add_c(
        & h1->c,
        & hr->c
        );
}

void trafo3d_th_mul_h(
        const Trafo3D   * t0,
        const HTrafo3D  * h0,
              HTrafo3D  * hr
        )
{
    c3_mm_mul_m(
        & t0->m,
        & h0->m,
        & hr->m
        );

    hr->c = h0->c;
}

void trafo3d_ht_mul_h(
        const HTrafo3D  * h0,
        const Trafo3D   * t0,
              HTrafo3D  * hr
        )
{
    c3_cm_mul_c(
        & h0->c,
        & t0->m,
        & hr->c
        );

    c3_mm_mul_m(
        & h0->m,
        & t0->m,
        & hr->m
        );
}

void trafo3d_v_local2world_from_worldspace_normal_t(
        const Vec3D    * in_vec,
              Trafo3D  * out_local2world
        )
{
    double x = fabs(XC(*in_vec));
    double y = fabs(YC(*in_vec));
    double z = fabs(ZC(*in_vec));

    Vec3D  vector;

    if (x < y)
    {
        if (x < z)
            vector = VEC3D_X_UNIT;
        else
            vector = VEC3D_Z_UNIT;
    }
    else
    {
        if (y < z)
            vector = VEC3D_Y_UNIT;
        else
            vector = VEC3D_Z_UNIT;
    }

    vec3d_vv_cross_v(
          in_vec,
        & vector,
          G3D_TR_X_VEC_P(*out_local2world)
        );

    vec3d_norm_v(
          G3D_TR_X_VEC_P(*out_local2world)
        );

    vec3d_vv_cross_v(
          in_vec,
          G3D_TR_X_VEC_P(*out_local2world),
          G3D_TR_Y_VEC_P(*out_local2world)
        );

    vec3d_norm_v(
          G3D_TR_Y_VEC_P(*out_local2world)
        );

    TRAFO3D_Z_VEC(*out_local2world) = *in_vec;
}

HTrafo3D* trafo3d_vvv_lookAt(
         Pnt3D *eye,
         Vec3D *forward,
         Vec3D *up
        )
{
    
    Vec3D right, adjusted_up;
    // cross product to define the right and adjusted_up
    vec3d_vv_cross_v(up, forward, &right);
    vec3d_vv_cross_v(forward, &right, &adjusted_up);
    
    
    double x = XC(right) * XC(*eye) + YC(right) * YC(*eye) + ZC(right) * ZC(*eye);
    double y = XC(adjusted_up) * XC(*eye) + YC(adjusted_up) * YC(*eye) + ZC(adjusted_up) * ZC(*eye);
    double z = XC(*forward) * XC(*eye) + YC(*forward) * YC(*eye) + ZC(*forward) * ZC(*eye);
    
    return &HTRAFO3D( XC(right), YC(right), ZC(right),
              XC(adjusted_up), YC(adjusted_up), ZC(adjusted_up),
              XC(*forward), YC(*forward), ZC(*forward),
              -x, -y, -z);
    
}


void trafo3d_v_world2local_from_worldspace_normal_t(
        const Vec3D    * in_vec,
              Trafo3D  * out_world2local
        )
{
    Vec3D  vector;

    double  x = fabs(XC(*in_vec));
    double  y = fabs(YC(*in_vec));
    double  z = fabs(ZC(*in_vec));

    if ( x < y )
    {
        if ( x < z )
            vector = VEC3D_X_UNIT;
        else
            vector = VEC3D_Z_UNIT;
    }
    else
    {
        if ( y < z )
            vector = VEC3D_Y_UNIT;
        else
            vector = VEC3D_Z_UNIT;
    }

    vec3d_vv_cross_v(
          in_vec,
        & vector,
          G3D_TR_X_VEC_P(*out_world2local) );

    vec3d_norm_v( G3D_TR_X_VEC_P(*out_world2local) );

    vec3d_vv_cross_v(
          in_vec,
          G3D_TR_X_VEC_P(*out_world2local),
          G3D_TR_Y_VEC_P(*out_world2local));

    vec3d_norm_v( & TRAFO3D_Y_VEC(*out_world2local) );

    TRAFO3D_Z_VEC(*out_world2local) = *in_vec;

    trafo3d_transpose_t( out_world2local );
}

void trafo3d_vv_align_m(
        const Vec3D  * v0,
        const Vec3D  * v1,
              Mat3   * mr
        )
{
    double v0_len = vec3d_v_len(v0);
    double v1_len = vec3d_v_len(v1);

    Vec3D  v0_norm, v1_norm;

    vec3d_dv_mul_v( 1. / v0_len, v0, & v0_norm );
    vec3d_dv_mul_v( 1. / v1_len, v1, & v1_norm );

    Vec3D   rotation_axis;
    
    vec3d_vv_cross_v( & v0_norm, & v1_norm, & rotation_axis );

    double rcos = vec3d_vv_dot( & v0_norm, & v1_norm );
    double rsin = vec3d_v_len( & rotation_axis );
    
    Mat3  rm;
    
    if ( rsin > 0. )
    {
        double  norm_factor = 1. / rsin;

        double u = XC(rotation_axis) * norm_factor;
        double v = YC(rotation_axis) * norm_factor;
        double w = ZC(rotation_axis) * norm_factor;

        rm.x[0][0] =      rcos + u*u*(1-rcos);
        rm.x[1][0] =  w * rsin + v*u*(1-rcos);
        rm.x[2][0] = -v * rsin + w*u*(1-rcos);
        rm.x[0][1] = -w * rsin + u*v*(1-rcos);
        rm.x[1][1] =      rcos + v*v*(1-rcos);
        rm.x[2][1] =  u * rsin + w*v*(1-rcos);
        rm.x[0][2] =  v * rsin + u*w*(1-rcos);
        rm.x[1][2] = -u * rsin + v*w*(1-rcos);
        rm.x[2][2] =      rcos + w*w*(1-rcos);

        c3_transpose_m( mr );
    }
    else
    {
        rm = MAT3_UNIT;
    }

    double  sr = v0_len / v1_len;
    
    Mat3  sm =
            MAT3( sr,  0,  0,
                   0, sr,  0,
                   0,  0, sr);

    c3_mm_mul_m( & rm, & sm, mr );
}

void trafo3d_vv_align_t(
        const Vec3D    * v0,
        const Vec3D    * v1,
              Trafo3D  * tr
        )
{
    trafo3d_vv_align_m(
          v0,
          v1,
        & tr->m
        );
}


void trafo3d_vt_perspective_transform_v(
        Vec3D *vec,
        Trafo4D *trafo,
        Vec3D *result
        )
{
    
    Mat4 matrix = trafo->m;
    
    double w = matrix.x[3][3];
    
    for(int i = 0; i < 3; i++)
    {
        w += matrix.x[3][i] * (vec->c.x[i]);
    }
    
    double inverseW = 1.0f / w;
    
    *result = VEC3D_INVALID;
    
    for(int r = 0; r < 3; r++)
    {
        
        result->c.x[r] = matrix.x[r][3];
        
        for(int c = 0; c < 3; c++)
        {
            result->c.x[r] += vec->c.x[c] * matrix.x[r][c];
        }
        
        result->c.x[r] *= inverseW;
    }
    
}


/* ======================================================================== */
