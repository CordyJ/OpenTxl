
double  tempVert( double in_temp )
{
        return( (5.0/9.0) * (in_temp - 32.0 ) );
}


int     main()
{
        int     count;
        double  fahren;
        
        for ( count=1; count <= 4; ++count )
        {
                printf( "Enter a Fahrenheit temp: " );
                scanf( "%f", &fahren );
                printf( "The Celsius equivalent is: %f\n", tempVert( fahren ) );
        }
}
